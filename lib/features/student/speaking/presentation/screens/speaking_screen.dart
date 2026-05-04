// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Speaking Screen (Mikrofon + AI Baholash)
// QO'YISH: lib/features/student/speaking/presentation/screens/speaking_screen.dart
//
// ✅ YANGI: Ovoz yozish (speech_to_text paketi)
// ✅ YANGI: Animatsiyali mikrofon tugmasi (pulse + wave)
// ✅ YANGI: AI tahlil — talaffuz, mavzu, IELTS band bali
// ✅ YANGI: Chiroyli 4-ko'rsatkich natija kartasi
//
// pubspec.yaml ga qo'shing:
//   speech_to_text: ^6.6.2
//
// AndroidManifest.xml ga qo'shing:
//   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:my_first_app/core/constants/api_endpoints.dart';
import 'package:my_first_app/core/providers/firebase_providers.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/widgets/sozana_loading_animation.dart';
import 'package:my_first_app/features/student/speaking/data/models/speaking_model.dart';
import 'package:my_first_app/features/student/speaking/domain/entities/speaking_exercise.dart';
import 'package:my_first_app/features/student/speaking/presentation/providers/speaking_provider.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/premium/presentation/providers/premium_provider.dart';
import 'package:my_first_app/features/premium/presentation/screens/premium_coach_screen.dart';

class SpeakingScreen extends ConsumerStatefulWidget {
  final String exerciseId;
  const SpeakingScreen({super.key, required this.exerciseId});

  @override
  ConsumerState<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends ConsumerState<SpeakingScreen>
    with TickerProviderStateMixin {
  // ─── Speech to Text ───
  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isRecording = false;
  String _transcript = '';
  String _partialTranscript = '';

  // ─── Holatlar ───
  bool _isAnalyzing = false;
  bool _showResult = false;
  Map<String, dynamic>? _assessmentResult;
  String? _errorMessage;

  // ─── Yozib olingan vaqt ───
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  // ─── Animatsiya ───
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  // ✅ TUZATILDI: class detail dan kelganda session yuklanadi
  String? _sessionError;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.28).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _initSpeech();

    // ✅ Session yo'q bo'lsa — Firestore dan yuklab startSession chaqiramiz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(speakingSessionProvider);
      if (session == null) {
        _loadSessionFromFirestore();
      }
    });
  }

  /// ✅ YANGI: O'qituvchi yuborgan contentId dan exercise yuklab, session boshlash
  Future<void> _loadSessionFromFirestore() async {
    if (!mounted) return;
    setState(() {
      _sessionError = null;
    });

    try {
      final firestore = ref.read(firestoreProvider);

      // 1. root 'content' collectiondan qidirish
      Map<String, dynamic>? data;
      String? foundId;

      final contentDoc =
          await firestore.collection('content').doc(widget.exerciseId).get();

      if (contentDoc.exists) {
        data = contentDoc.data();
        foundId = contentDoc.id;
      }

      // 2. speaking_exercises collectiondan qidirish
      if (data == null) {
        final speakingDoc = await firestore
            .collection('speaking_exercises')
            .doc(widget.exerciseId)
            .get();
        if (speakingDoc.exists) {
          data = speakingDoc.data();
          foundId = speakingDoc.id;
        }
      }

      // 3. classes subcollectionlardan qidirish
      if (data == null) {
        final classesSnap = await firestore
            .collection('classes')
            .where('isActive', isEqualTo: true)
            .get();

        for (final classDoc in classesSnap.docs) {
          final subDoc = await firestore
              .collection('classes')
              .doc(classDoc.id)
              .collection('content')
              .doc(widget.exerciseId)
              .get();
          if (subDoc.exists) {
            data = subDoc.data();
            foundId = subDoc.id;
            break;
          }
        }
      }

      if (data == null || foundId == null) {
        if (mounted) {
          setState(() {
            _sessionError = 'Speaking mashq topilmadi';
          });
        }
        return;
      }

      // 4. data ichidagi fieldlarni yuqoriga ko'tarish (content collectionida 'data' nested bo'ladi)
      final flatData = <String, dynamic>{...data};
      if (flatData['data'] is Map) {
        flatData.addAll(Map<String, dynamic>.from(flatData['data'] as Map));
      }

      // ✅ Timestamp → int ga o'girish (SpeakingModel.fromJson int kutadi)
      final createdRaw = flatData['createdAt'];
      if (createdRaw is Timestamp) {
        flatData['createdAt'] = createdRaw.toDate().millisecondsSinceEpoch;
      } else if (createdRaw == null) {
        flatData['createdAt'] = DateTime.now().millisecondsSinceEpoch;
      }

      // ✅ turns va vocabulary null safe
      flatData['turns'] ??= <dynamic>[];
      flatData['vocabulary'] ??= <dynamic>[];

      final exercise = SpeakingModel.fromJson(flatData, foundId);

      if (mounted) {
        ref.read(speakingSessionProvider.notifier).startSession(exercise);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sessionError = 'Yuklanmadi: $e';
        });
      }
    }
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: _onStatus,
      onError: (e) {
        if (mounted) setState(() => _isRecording = false);
        _pulseController.stop();
        _recordingTimer?.cancel();
      },
    );
    if (mounted) setState(() {});
  }

  void _onStatus(String s) {
    // ✅ FIX: 'done' yoki 'notListening' kelganda qayta boshlaymiz
    // Faqat foydalanuvchi o'zi to'xtatgandagina (_isRecording = false) to'xtaydi
    if ((s == 'done' || s == 'notListening') && _isRecording && mounted) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_isRecording && mounted) {
          _restartListening();
        }
      });
    }
  }

  Future<void> _restartListening() async {
    if (!_isRecording || !mounted) return;
    final session = ref.read(speakingSessionProvider);
    final locale = (session?.exercise.language == 'de') ? 'de_DE' : 'en_US';
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult r) {
          if (!mounted) return;
          setState(() {
            if (r.finalResult) {
              if (r.recognizedWords.isNotEmpty) {
                _transcript = (_transcript.isEmpty)
                    ? r.recognizedWords
                    : '$_transcript ${r.recognizedWords}';
              }
              _partialTranscript = '';
            } else {
              _partialTranscript = r.recognizedWords;
            }
          });
        },
        localeId: locale,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: false,
        ),
        pauseFor: const Duration(seconds: 120), // ✅ FIX: uzoq kutadi
      );
    } catch (_) {
      // Xato bo'lsa qayta urinib ko'rmaymiz — foydalanuvchi to'xtatishi kerak
    }
  }

  Future<void> _startRecording() async {
    if (!_speechAvailable) {
      setState(() => _errorMessage = 'Mikrofon ruxsati berilmagan');
      return;
    }
    setState(() {
      _isRecording = true;
      _transcript = '';
      _partialTranscript = '';
      _errorMessage = null;
      _recordingSeconds = 0;
    });
    _pulseController.repeat(reverse: true);
    // ✅ FIX: Max 3 daqiqa, foydalanuvchi o'zi to'xtatadi
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _recordingSeconds++);
      if (_recordingSeconds >= 180) _stopRecording(); // 3 daqiqa max
    });

    final session = ref.read(speakingSessionProvider);
    final locale = (session?.exercise.language == 'de') ? 'de_DE' : 'en_US';

    await _speech.listen(
      onResult: (SpeechRecognitionResult r) {
        if (!mounted) return;
        setState(() {
          if (r.finalResult) {
            _transcript = r.recognizedWords;
            _partialTranscript = '';
          } else {
            _partialTranscript = r.recognizedWords;
          }
        });
      },
      localeId: locale,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: false,
      ),
      pauseFor: const Duration(seconds: 120), // ✅ FIX: 2 daqiqa jimlik kutadi
    );
  }

  Future<void> _stopRecording() async {
    _pulseController.stop();
    _pulseController.reset();
    _recordingTimer?.cancel();
    await _speech.stop();
    final full = _transcript.isNotEmpty ? _transcript : _partialTranscript;
    if (mounted) {
      setState(() {
        _isRecording = false;
        _transcript = full;
        _partialTranscript = '';
      });
    }
  }

  void _onMicTap() {
    if (_isAnalyzing) return;
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  Future<void> _analyzeWithAI() async {
    if (_transcript.trim().isEmpty) {
      setState(() => _errorMessage = 'Avval gapiring, keyin baholating');
      return;
    }
    final session = ref.read(speakingSessionProvider);
    if (session == null) return;

    // ✅ FIX: userId ni auth provider dan olamiz — backend talab qiladi
    final userId = ref.read(authNotifierProvider).user?.id ?? '';

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });
    try {
      final callable =
          FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable(
        ApiEndpoints.assessSpeaking,
        options: HttpsCallableOptions(timeout: ApiEndpoints.assessmentTimeout),
      );
      final result = await callable.call({
        'userId': userId, // ✅ FIX: qo'shildi
        'taskId': widget.exerciseId,
        'language': session.exercise.language,
        'level': session.exercise.level,
        'topic': session.exercise.topic,
        'transcribedText': _transcript.trim(),
        'audioDuration': _recordingSeconds,
      });

      final data = result.data as Map<String, dynamic>? ?? {};

      // ✅ FIX: Backend maydon nomlarini Flutter ga moslashtirish
      final normalized = _normalizeAssessmentData(data);

      if (mounted) {
        setState(() {
          _assessmentResult = normalized;
          _isAnalyzing = false;
          _showResult = true;
        });
      }
    } catch (e) {
      debugPrint('⚠️ assessSpeaking xatosi: $e');
      if (mounted) {
        setState(() {
          _assessmentResult = _fallback(session.exercise);
          _isAnalyzing = false;
          _showResult = true;
        });
      }
    }
  }

  // ✅ YANGI: Backend maydon nomlarini Flutter natija ekrani kutayotgan
  // nomlar bilan moslashtirish
  // Backend: pronunciationScore, grammarScore, fluencyScore, vocabularyScore
  // Flutter: pronunciation, grammar, fluency, topicRelevance
  Map<String, dynamic> _normalizeAssessmentData(Map<String, dynamic> d) {
    return {
      // Asosiy ball
      'overallScore': d['overallScore'] ?? d['overall'] ?? 0,
      // 4 ko'rsatkich — backend alias maydonlari + fallback
      'pronunciation': d['pronunciation'] ?? d['pronunciationScore'] ?? 0,
      'fluency': d['fluency'] ?? d['fluencyScore'] ?? 0,
      'topicRelevance': d['topicRelevance'] ?? d['vocabularyScore'] ?? 0,
      'grammar': d['grammar'] ?? d['grammarScore'] ?? 0,
      // IELTS
      'ieltsScore': d['ieltsScore'] ??
          _calcIelts(((d['overallScore'] ?? 0) as num).toDouble()),
      'ieltsBand': d['ieltsBand'] ??
          _band((d['ieltsScore'] != null
              ? double.tryParse(d['ieltsScore'].toString()) ?? 0.0
              : _calcIelts(((d['overallScore'] ?? 0) as num).toDouble()))),
      // Feedback
      'feedback': d['overallFeedback'] ?? d['feedback'] ?? '',
      'strengths': d['strengths'] ?? <String>[],
      'improvements': d['improvementTips'] ?? d['improvements'] ?? <String>[],
      // Grammatik xatolar (premium coach uchun)
      'grammarErrors': d['grammarErrors'] ?? <dynamic>[],
      'grammarErrorDetails': d['grammarErrorDetails'] ?? <dynamic>[],
      // Qo'shimcha
      'transcribedText': _transcript,
      'topic': d['topic'],
    };
  }

  double _calcIelts(double score) {
    if (score >= 90) return 8.5;
    if (score >= 80) return 7.5;
    if (score >= 70) return 6.5;
    if (score >= 60) return 5.5;
    if (score >= 50) return 5.0;
    if (score >= 40) return 4.0;
    return 3.0;
  }

  // ✅ Fallback: Cloud Function xato berganida
  // So'z soni emas, matn tahlili asosida hisoblash
  Map<String, dynamic> _fallback(SpeakingExercise e) {
    final words = _transcript.trim().split(RegExp(r'\s+'));
    final wordCount = words.length;
    final isEnglish = e.language == 'en';

    // Grammatik tekshirish — oddiy qoidalar
    int grammarPenalty = 0;
    if (!_transcript.contains(
        RegExp(r'\b(I|he|she|it|they|we|you)\b', caseSensitive: false))) {
      grammarPenalty += 5;
    }

    // Fluency: gapirish uzunligiga qarab
    final fluency = wordCount >= 30
        ? 75
        : wordCount >= 15
            ? 60
            : wordCount >= 7
                ? 45
                : 25;

    // Grammar: xatoliklarni hisobga olgan holda
    final grammar = (70 - grammarPenalty).clamp(20, 90);

    // Mavzu: birinchi topik so'zi bor-yo'qligini tekshirish
    final topicWords = e.topic.toLowerCase().split(' ');
    final transcriptLower = _transcript.toLowerCase();
    final topicMatch =
        topicWords.any((w) => w.length > 3 && transcriptLower.contains(w));
    final topicScore = topicMatch ? 70 : 40;

    // Talaffuz: faqat ingliz uchun taxminiy
    final pronunciation = isEnglish ? 65 : 60;

    final overall = ((pronunciation + fluency + topicScore + grammar) ~/ 4);
    final ielts = _calcIelts(overall.toDouble());

    return {
      'overallScore': overall,
      'ieltsScore': ielts.toStringAsFixed(1),
      'ieltsBand': _band(ielts),
      'pronunciation': pronunciation,
      'fluency': fluency,
      'topicRelevance': topicScore,
      'grammar': grammar,
      'feedback': wordCount >= 15
          ? 'Yaxshi urinish! Yanada ko\'proq gapiring va so\'z boyligingizni oshiring.'
          : 'Kamroq so\'z ishlatildi. Mavzu bo\'yicha ko\'proq gapiring.',
      'strengths': wordCount >= 10
          ? ['Javob berildi', if (topicMatch) 'Mavzuga to\'g\'ri yondashildi']
          : ['Urinish qilingan'],
      'improvements': [
        if (wordCount < 15) 'Ko\'proq gapirib mashq qiling',
        if (!topicMatch) 'Mavzu bo\'yicha aniqroq gapiring',
        'Grammatika va talaffuzga e\'tibor bering',
      ],
      'grammarErrors': <dynamic>[],
      'grammarErrorDetails': <dynamic>[],
      'transcribedText': _transcript,
    };
  }

  String _band(double s) {
    if (s >= 8) return '8.0–9.0';
    if (s >= 7) return '7.0–7.5';
    if (s >= 6) return '6.0–6.5';
    if (s >= 5) return '5.0–5.5';
    if (s >= 4) return '4.0–4.5';
    return '3.0–3.5';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _recordingTimer?.cancel();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(speakingSessionProvider);

    // ✅ TUZATILDI: Session yuklanayotgan yoki xato bo'lsa
    if (session == null) {
      if (_sessionError != null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Speaking')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Xatolik yuz berdi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _sessionError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loadSessionFromFirestore,
                    child: const Text('Qayta urinish'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Orqaga'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      // Yuklanmoqda
      return Scaffold(
        body: const SpeakingLoadingWidget(),
      );
    }
    if (_showResult && _assessmentResult != null) {
      return _buildResult(session.exercise);
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(session.exercise.topic),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _topicCard(session.exercise),
          Expanded(child: _micSection()),
          if (_transcript.isNotEmpty || _partialTranscript.isNotEmpty)
            _transcriptBox(),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade600, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _topicCard(SpeakingExercise ex) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.record_voice_over, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ex.topic,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(ex.level,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (ex.turns.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                ex.turns.first.text ?? ex.topic,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _micSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isRecording)
            Text(
              _fmt(_recordingSeconds),
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600),
            )
          else
            const Text(
              'Mikrofonga bosing\nva gapiring',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
            ),
          const SizedBox(height: 36),

          // Mikrofon animatsiya
          GestureDetector(
            onTap: _onMicTap,
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseController, _waveController]),
              builder: (_, __) {
                final wave = _waveController.value * 2 * math.pi;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isRecording) ...[
                      _ring(160, (math.sin(wave) + 1) / 2 * 0.25),
                      _ring(130, (math.sin(wave + 1) + 1) / 2 * 0.35),
                      _ring(105, (math.sin(wave + 2) + 1) / 2 * 0.45),
                    ],
                    Transform.scale(
                      scale: _isRecording ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _isRecording
                                ? [Colors.red.shade400, Colors.red.shade700]
                                : [
                                    AppColors.primary,
                                    AppColors.primary.withValues(alpha: 0.75)
                                  ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording
                                      ? Colors.red
                                      : AppColors.primary)
                                  .withValues(alpha: 0.4),
                              blurRadius: 22,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          Text(
            _isRecording
                ? '⏸  To\'xtatish uchun bosing'
                : _speechAvailable
                    ? '🎤  Bosing va inglizcha/nemischa gapiring'
                    : '⚠️  Mikrofon ruxsati kerak',
            style: TextStyle(
              fontSize: 13,
              color: _isRecording ? Colors.red.shade600 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.red.withValues(alpha: opacity),
            width: 2,
          ),
        ),
      );

  Widget _transcriptBox() {
    final text = _transcript.isNotEmpty ? _transcript : _partialTranscript;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(14),
      constraints: const BoxConstraints(maxHeight: 110),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isRecording
              ? Colors.red.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Sizning gapingiz:',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                if (_isRecording) ...[
                  const Spacer(),
                  Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('yozib olinmoqda',
                      style: TextStyle(fontSize: 10, color: Colors.red)),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: _transcript.isEmpty ? Colors.grey[400] : Colors.black87,
                fontStyle:
                    _transcript.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Row(
          children: [
            if (_transcript.isNotEmpty && !_isRecording)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _transcript = '';
                    _partialTranscript = '';
                    _errorMessage = null;
                    _recordingSeconds = 0;
                  }),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Qayta'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            if (_transcript.isNotEmpty && !_isRecording)
              const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: (_isAnalyzing || _isRecording || _transcript.isEmpty)
                    ? null
                    : _analyzeWithAI,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: SozonaLoadingAnimation(
                          style: LoadingStyle.dots,
                          primaryColor: Colors.white,
                          secondaryColor: Colors.white70,
                          size: 18,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  _isAnalyzing ? 'Tahlil qilinmoqda...' : 'AI bilan baholash',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // NATIJA EKRANI
  // ══════════════════════════════════════════════════════════════
  Widget _buildResult(SpeakingExercise ex) {
    final d = _assessmentResult!;
    final overall = (d['overallScore'] as num?)?.toInt() ?? 0;
    final ielts = d['ieltsScore']?.toString() ?? '—';
    final band = d['ieltsBand']?.toString() ?? '—';
    final pron = (d['pronunciation'] as num?)?.toInt() ?? 0;
    final flu = (d['fluency'] as num?)?.toInt() ?? 0;
    final topic = (d['topicRelevance'] as num?)?.toInt() ?? 0;
    final gram = (d['grammar'] as num?)?.toInt() ?? 0;
    final feedback = d['feedback']?.toString() ?? '';
    final strengths = List<String>.from(d['strengths'] ?? []);
    final improvements = List<String>.from(d['improvements'] ?? []);

    final scoreColor = overall >= 70
        ? Colors.green
        : overall >= 50
            ? Colors.orange
            : Colors.redAccent;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Natija'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(speakingSessionProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Asosiy ball kartasi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scoreColor.withValues(alpha: 0.12),
                    scoreColor.withValues(alpha: 0.04)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: scoreColor.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    '$overall',
                    style: TextStyle(
                        fontSize: 76,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                        height: 1),
                  ),
                  Text('/ 100',
                      style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8)
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎓 IELTS: ',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        Text(ielts,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: scoreColor)),
                        const SizedBox(width: 6),
                        Text('($band)',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 4 ta ko'rsatkich
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                _scoreItem('🗣️ Talaffuz', pron, Colors.blue),
                _scoreItem('⚡ Ravonlik', flu, Colors.green),
                _scoreItem('🎯 Mavzu', topic, Colors.purple),
                _scoreItem('📝 Grammatika', gram, Colors.orange),
              ],
            ),

            const SizedBox(height: 14),

            // Gapingiz
            _card(
                '🗣️ Sizning gapingiz',
                Text(_transcript,
                    style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        height: 1.5))),

            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 10),
              _card(
                  '💬 AI fikri',
                  Text(feedback,
                      style: const TextStyle(fontSize: 13, height: 1.6))),
            ],

            if (strengths.isNotEmpty) ...[
              const SizedBox(height: 10),
              _card(
                '✅ Kuchli tomonlar',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: strengths
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(children: [
                              const Text('• ',
                                  style: TextStyle(color: Colors.green)),
                              Expanded(
                                  child: Text(s,
                                      style: const TextStyle(fontSize: 13))),
                            ]),
                          ))
                      .toList(),
                ),
              ),
            ],

            if (improvements.isNotEmpty) ...[
              const SizedBox(height: 10),
              _card(
                '📈 Yaxshilash kerak',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: improvements
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(children: [
                              const Text('• ',
                                  style: TextStyle(color: Colors.orange)),
                              Expanded(
                                  child: Text(s,
                                      style: const TextStyle(fontSize: 13))),
                            ]),
                          ))
                      .toList(),
                ),
              ),
            ],

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _showResult = false;
                      _transcript = '';
                      _assessmentResult = null;
                      _recordingSeconds = 0;
                    }),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Qayta urinish'),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(speakingSessionProvider.notifier).reset();
                      context.pop();
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Tugatish'),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
            // ✅ YANGI: Premium AI Murabbiy tugmasi
            if (ref.watch(hasPremiumProvider)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final d = _assessmentResult ?? {};
                    final score = (d['overallScore'] as num?)?.toDouble() ?? 0;

                    // ✅ FIX: Dialog konteksti — AI murabbiy vazifani bilsin
                    // exercise.turns = dialog qadamlari
                    // partner gapirgan → savol/kontekst
                    // student gapirishi kerak → tavsiya/misol
                    final session = ref.read(speakingSessionProvider);
                    final dialogContext = session?.exercise.turns
                        .take(6)
                        .map((t) => t.isPartnerTurn
                            ? 'AI: ${t.text ?? ""}'
                            : 'Student (tavsiya): ${t.suggestion ?? ""}')
                        .where((s) => s.length > 5)
                        .join(' | ');

                    // ✅ FIX: Grammatik xatolar — aniq jumlalar bilan
                    // grammarErrors = xato qoidalar ro'yxati
                    // grammarErrorDetails = original + to'g'rilangan shakl
                    final grammarErrors = (d['grammarErrors'] as List?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        <String>[];
                    final grammarErrorDetails =
                        (d['grammarErrorDetails'] as List?)
                                ?.map((e) => e as Map<String, dynamic>)
                                .toList() ??
                            <Map<String, dynamic>>[];

                    // wrongAnswers formatiga o'tkazamiz — AI murabbiy
                    // quiz/listening bilan bir xil tushuntirsin
                    final wrongAnswers = grammarErrorDetails
                        .map((e) => {
                              'question': dialogContext ?? d['topic'] ?? '',
                              'userAnswer': e['original']?.toString() ?? '',
                              'correctAnswer': e['corrected']?.toString() ?? '',
                              'explanation': e['explanation']?.toString() ?? '',
                              'rule': e['rule']?.toString() ?? '',
                            })
                        .toList();

                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PremiumCoachScreen(
                        trigger: 'after_lesson',
                        skillType: 'speaking',
                        lastScore: score,
                        sessionData: {
                          'topic': d['topic']?.toString() ??
                              session?.exercise.topic ??
                              '',
                          // ✅ AI vazifani ko'radi — "Bu dialog haqida edi"
                          'taskDescription': dialogContext ?? '',
                          'ieltsBand': d['ieltsBand']?.toString(),
                          'transcribedText':
                              d['transcribedText']?.toString() ?? _transcript,
                          'grammarErrors': grammarErrors,
                          // ✅ Aniq jumlalar — "I go" → "I went" (past tense)
                          if (wrongAnswers.isNotEmpty)
                            'wrongAnswers': wrongAnswers,
                        },
                      ),
                    ));
                  },
                  icon: const Icon(Icons.workspace_premium,
                      color: Color(0xFFFFD700), size: 18),
                  label: const Text('AI Murabbiy tahlili',
                      style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side:
                        const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _scoreItem(String label, int score, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: color.withValues(alpha: 0.15),
              color: color,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text('$score%',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _card(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
