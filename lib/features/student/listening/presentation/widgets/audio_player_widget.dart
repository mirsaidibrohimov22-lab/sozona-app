// lib/features/student/listening/presentation/widgets/audio_player_widget.dart
// ✅ TUZATILDI: TTS uchun ham davomiylik va progress bar
// ✅ TUZATILDI: seekToPosition - savol timestamp ga audio seek
// ✅ TUZATILDI: Vaqt doim ko'rsatiladi
// ✅ FIX v4.0: StreamSubscription dispose qilindi — '_dependents.isEmpty' xatosi hal qilindi
// ✅ FIX v5.0: Premium foydalanuvchilar uchun OpenAI TTS ovoz tanlash qo'shildi
//    - useOpenAiTts: true bo'lsa — generateSpeech Cloud Function chaqiriladi
//    - Ovoz tanlash: nova (default), alloy, echo, shimmer
//    - Audio base64 dan just_audio orqali ijro etiladi

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:my_first_app/core/theme/app_colors.dart';

// OpenAI TTS ovozlari
enum OpenAiVoice {
  nova('nova', 'Nova (tavsiya)'),
  alloy('alloy', 'Alloy'),
  echo('echo', 'Echo'),
  shimmer('shimmer', 'Shimmer');

  const OpenAiVoice(this.id, this.label);
  final String id;
  final String label;
}

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String transcript;
  final String language;
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final Duration? seekToPosition;
  final VoidCallback onPlayPause;
  final Function(Duration) onSeek;
  final VoidCallback? onSeekDone;
  // ✅ YANGI: Premium OpenAI TTS
  final bool useOpenAiTts;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.transcript = '',
    this.language = 'en',
    required this.isPlaying,
    required this.currentPosition,
    required this.totalDuration,
    this.seekToPosition,
    required this.onPlayPause,
    required this.onSeek,
    this.onSeekDone,
    this.useOpenAiTts = false, // default: device TTS
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  AudioPlayer? _audioPlayer;
  final FlutterTts _tts = FlutterTts();
  bool _isTtsMode = false;
  bool _ttsPlaying = false;
  double _playbackSpeed = 1.0;

  // ✅ FIX: StreamSubscription'larni saqlash
  StreamSubscription? _positionSub;
  StreamSubscription? _playerStateSub;

  // TTS vaqt kuzatuvi
  Duration _ttsPosition = Duration.zero;
  Duration _ttsDuration = Duration.zero;

  // ✅ OpenAI TTS holati
  OpenAiVoice _selectedVoice = OpenAiVoice.nova;
  bool _openAiLoading = false;
  bool _openAiReady = false; // audio yuklandi, tayyor
  String? _openAiError;

  @override
  void initState() {
    super.initState();
    _isTtsMode = widget.audioUrl.isEmpty;
    if (_isTtsMode) {
      _initTts();
    } else {
      _initAudioPlayer();
    }
  }

  Future<void> _initTts() async {
    final locale = widget.language == 'de' ? 'de-DE' : 'en-US';
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _updateTtsDuration(0.45);

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _ttsPlaying = false;
          _ttsPosition = _ttsDuration;
        });
        widget.onSeek(_ttsDuration);
      }
    });

    _tts.setProgressHandler((text, start, end, word) {
      if (mounted && widget.transcript.isNotEmpty) {
        final ratio = start / widget.transcript.length;
        final pos = Duration(
            milliseconds: (_ttsDuration.inMilliseconds * ratio).round());
        setState(() => _ttsPosition = pos);
        widget.onSeek(pos);
      }
    });
  }

  void _updateTtsDuration(double rate) {
    final charCount = widget.transcript.length;
    final secs = (charCount * 0.07 / rate.clamp(0.1, 2.0)).round();
    _ttsDuration = Duration(seconds: secs.clamp(5, 600));
    widget.onSeek(Duration(seconds: _ttsDuration.inSeconds));
  }

  Future<void> _ttsPlayPause() async {
    if (_ttsPlaying) {
      await _tts.stop();
      if (mounted) setState(() => _ttsPlaying = false);
    } else {
      final text = widget.transcript.isNotEmpty
          ? widget.transcript
          : 'No transcript available';
      setState(() {
        _ttsPlaying = true;
        _ttsPosition = Duration.zero;
      });
      await _tts.speak(text);
    }
  }

  // ✅ OpenAI TTS: Cloud Function'dan audio olish va ijro etish
  Future<void> _generateAndPlayOpenAiTts() async {
    if (widget.transcript.isEmpty) return;
    if (_openAiLoading) return;

    // Agar allaqachon audio bor bo'lsa — faqat play/pause
    if (_openAiReady && _audioPlayer != null) {
      if (widget.isPlaying) {
        _audioPlayer!.pause();
      } else {
        _audioPlayer!.play();
      }
      widget.onPlayPause();
      return;
    }

    setState(() {
      _openAiLoading = true;
      _openAiError = null;
    });

    try {
      final callable =
          FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable(
        'generateSpeech',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );

      final result = await callable.call({
        'text': widget.transcript,
        'voice': _selectedVoice.id,
        'speed': _playbackSpeed,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final base64Audio = data['audio'] as String;
      final audioBytes = base64Decode(base64Audio);

      // just_audio orqali memory'dan ijro
      _audioPlayer?.dispose();
      _audioPlayer = AudioPlayer();

      // Bytes stream sifatida yuklaymiz
      final source = _BytesAudioSource(Uint8List.fromList(audioBytes));
      await _audioPlayer!.setAudioSource(source);

      // Duration
      final dur = _audioPlayer!.duration ?? const Duration(seconds: 30);
      widget.onSeek(dur);

      _positionSub?.cancel();
      _playerStateSub?.cancel();

      _positionSub = _audioPlayer!.positionStream.listen((pos) {
        if (mounted) widget.onSeek(pos);
      });

      _playerStateSub = _audioPlayer!.playerStateStream.listen((ps) {
        if (ps.processingState == ProcessingState.completed) {
          if (mounted) {
            _audioPlayer!.seek(Duration.zero);
            _audioPlayer!.pause();
          }
        }
      });

      if (mounted) {
        setState(() {
          _openAiLoading = false;
          _openAiReady = true;
          _isTtsMode = false; // real audio player ishlatamiz
        });
      }

      await _audioPlayer!.play();
      widget.onPlayPause();
    } catch (e) {
      if (!mounted) return;

      // ✅ FIX: Xato turini aniqlab, mos xabar ko'rsatish
      String errorMsg;
      bool fallbackToDeviceTts = false;

      if (e is FirebaseFunctionsException) {
        switch (e.code) {
          case 'permission-denied':
            // Premium yo'q — device TTS ga o'tkazamiz
            errorMsg = 'OpenAI ovoz faqat premium uchun';
            fallbackToDeviceTts = true;
            break;
          case 'unauthenticated':
            errorMsg = 'Tizimga kirish kerak';
            fallbackToDeviceTts = true;
            break;
          case 'deadline-exceeded':
          case 'unavailable':
            errorMsg = 'Server band. Device ovozi ishlatilmoqda.';
            fallbackToDeviceTts = true;
            break;
          default:
            errorMsg = 'OpenAI xatosi: ${e.message ?? e.code}';
            fallbackToDeviceTts = true;
        }
      } else {
        errorMsg = 'Ovoz yuklanmadi. Device ovozi ishlatilmoqda.';
        fallbackToDeviceTts = true;
      }

      setState(() {
        _openAiLoading = false;
        _openAiError = errorMsg;
      });

      // ✅ FIX: Xato bo'lsa device TTS ga avtomatik o'tkazish
      if (fallbackToDeviceTts) {
        // Qisqa kutib, keyin device TTS bilan o'ynash
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          setState(() {
            _openAiError = null; // xato xabarini tozalaymiz
          });
          await _ttsPlayPause(); // device TTS bilan o'ynash
        }
      }
    }
  }

  // Ovoz o'zgarganda audionu qayta yuklaymiz
  Future<void> _changeVoice(OpenAiVoice voice) async {
    if (_selectedVoice == voice) return;
    setState(() {
      _selectedVoice = voice;
      _openAiReady = false; // qayta yuklanadi
      _openAiError = null;
    });
    _audioPlayer?.stop();
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer!.setUrl(widget.audioUrl);

      _positionSub = _audioPlayer!.positionStream.listen((pos) {
        if (mounted) widget.onSeek(pos);
      });

      _playerStateSub = _audioPlayer!.playerStateStream.listen((ps) {
        if (ps.processingState == ProcessingState.completed) {
          if (mounted) {
            _audioPlayer!.seek(Duration.zero);
            _audioPlayer!.pause();
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isTtsMode = true);
        await _initTts();
      }
    }
  }

  @override
  void didUpdateWidget(AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.seekToPosition != null &&
        widget.seekToPosition != oldWidget.seekToPosition) {
      if (!_isTtsMode && _audioPlayer != null) {
        _audioPlayer?.seek(widget.seekToPosition ?? Duration.zero);
      }
      // ✅ FIX: build paytida provider o'zgartirish xatosi — Future bilan kechiktirish
      Future(() => widget.onSeekDone?.call());
    }

    if (!_isTtsMode && _audioPlayer != null) {
      if (oldWidget.isPlaying != widget.isPlaying) {
        widget.isPlaying ? _audioPlayer!.play() : _audioPlayer!.pause();
      }
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _audioPlayer?.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // OpenAI TTS rejimi: audio tayyor bo'lsa real player, aks holda TTS
    final isOpenAiMode = widget.useOpenAiTts && _isTtsMode;
    final isPlaying =
        _isTtsMode && !_openAiReady ? _ttsPlaying : widget.isPlaying;

    final totalDur = _isTtsMode && !_openAiReady
        ? (_ttsDuration == Duration.zero
            ? const Duration(seconds: 1)
            : _ttsDuration)
        : (widget.totalDuration == Duration.zero
            ? const Duration(seconds: 1)
            : widget.totalDuration);

    final curPos =
        _isTtsMode && !_openAiReady ? _ttsPosition : widget.currentPosition;
    final sliderMax = totalDur.inSeconds.toDouble().clamp(1.0, 3600.0);
    final sliderVal = curPos.inSeconds.toDouble().clamp(0.0, sliderMax);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // ── Ovoz tanlash (faqat premium + TTS rejimda) ──────────
          if (widget.useOpenAiTts && _isTtsMode && !_openAiReady)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎙️', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  const Text('OpenAI ovoz:',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  DropdownButton<OpenAiVoice>(
                    value: _selectedVoice,
                    isDense: true,
                    underline: const SizedBox(),
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF6D4C41)),
                    items: OpenAiVoice.values.map((v) {
                      return DropdownMenuItem(value: v, child: Text(v.label));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) _changeVoice(v);
                    },
                  ),
                ],
              ),
            ),

          // ── Xato xabari ─────────────────────────────────────────
          if (_openAiError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _openAiError!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),

          // ── Device TTS badge (premium emas) ─────────────────────
          if (_isTtsMode && !widget.useOpenAiTts)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.record_voice_over,
                      size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Text('AI ovoz (TTS)',
                      style:
                          TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                ],
              ),
            ),

          // ── Slider ──────────────────────────────────────────────
          SliderTheme(
            data: const SliderThemeData(
              trackHeight: 4,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: sliderVal,
              max: sliderMax,
              onChanged: (_isTtsMode && !_openAiReady)
                  ? null
                  : (v) => _audioPlayer?.seek(Duration(seconds: v.toInt())),
              activeColor: widget.useOpenAiTts
                  ? const Color(0xFFFFD700)
                  : AppColors.primary,
              inactiveColor: Colors.grey.shade300,
            ),
          ),

          // ── Vaqt ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(curPos),
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(_fmt(totalDur),
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Controls ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isTtsMode || _openAiReady)
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  iconSize: 32,
                  onPressed: () {
                    final pos =
                        widget.currentPosition - const Duration(seconds: 10);
                    _audioPlayer?.seek(pos.isNegative ? Duration.zero : pos);
                  },
                ),
              const SizedBox(width: 16),

              // Play tugmasi
              GestureDetector(
                onTap: () {
                  if (widget.useOpenAiTts && _isTtsMode && !_openAiReady) {
                    // OpenAI TTS: yuklab ijro etish
                    _generateAndPlayOpenAiTts();
                  } else if (_isTtsMode) {
                    // Oddiy device TTS
                    _ttsPlayPause();
                  } else {
                    widget.onPlayPause();
                  }
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: widget.useOpenAiTts
                        ? const Color(0xFFFFD700)
                        : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _openAiLoading
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                ),
              ),

              const SizedBox(width: 16),
              if (!_isTtsMode || _openAiReady)
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  iconSize: 32,
                  onPressed: () {
                    final pos =
                        widget.currentPosition + const Duration(seconds: 10);
                    _audioPlayer?.seek(pos > widget.totalDuration
                        ? widget.totalDuration
                        : pos);
                  },
                ),
              const SizedBox(width: 8),

              // Tezlik
              PopupMenuButton<double>(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${_playbackSpeed}x',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
                onSelected: (speed) async {
                  setState(() => _playbackSpeed = speed);
                  if (_isTtsMode && !_openAiReady) {
                    await _tts.setSpeechRate((speed * 0.45).clamp(0.2, 0.9));
                    _updateTtsDuration(speed * 0.45);
                    setState(() {});
                  } else {
                    _audioPlayer?.setSpeed(speed);
                  }
                },
                itemBuilder: (_) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
                  return PopupMenuItem(
                    value: s,
                    child: Row(children: [
                      if (_playbackSpeed == s)
                        const Icon(Icons.check,
                            size: 18, color: AppColors.primary),
                      if (_playbackSpeed == s) const SizedBox(width: 6),
                      Text('${s}x'),
                    ]),
                  );
                }).toList(),
              ),
            ],
          ),

          if (_isTtsMode && !_openAiReady) ...[
            const SizedBox(height: 4),
            Text(
              _openAiLoading
                  ? '⏳ OpenAI ovoz yuklanmoqda...'
                  : widget.useOpenAiTts
                      ? '▶ Bosing — OpenAI ovozi bilan tinglang'
                      : (isPlaying
                          ? '🔊 O\'qilmoqda...'
                          : '▶ Play tugmasini bosing'),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── just_audio uchun bytes-dan audio source ─────────────────────────────────
class _BytesAudioSource extends StreamAudioSource {
  final Uint8List _bytes;
  _BytesAudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(List<int>.from(_bytes.sublist(start, end))),
      contentType: 'audio/mpeg',
    );
  }
}
