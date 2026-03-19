// lib/features/student/listening/presentation/widgets/audio_player_widget.dart
// ✅ TUZATILDI: TTS uchun ham davomiylik va progress bar
// ✅ TUZATILDI: seekToPosition - savol timestamp ga audio seek
// ✅ TUZATILDI: Vaqt doim ko'rsatiladi

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:my_first_app/core/theme/app_colors.dart';

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

  // TTS vaqt kuzatuvi
  Duration _ttsPosition = Duration.zero;
  Duration _ttsDuration = Duration.zero;

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

    // Taxminiy davomiylik
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

    // Progress
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

  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer!.setUrl(widget.audioUrl);

      _audioPlayer!.positionStream.listen((pos) {
        if (mounted) widget.onSeek(pos);
      });

      _audioPlayer!.playerStateStream.listen((ps) {
        if (ps.processingState == ProcessingState.completed) {
          _audioPlayer!.seek(Duration.zero);
          _audioPlayer!.pause();
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

    // ✅ Savol o'zgarganda audio seek
    if (widget.seekToPosition != null &&
        widget.seekToPosition != oldWidget.seekToPosition) {
      if (!_isTtsMode && _audioPlayer != null) {
        _audioPlayer?.seek(widget.seekToPosition ?? Duration.zero);
      }
      widget.onSeekDone?.call();
    }

    if (!_isTtsMode && _audioPlayer != null) {
      if (oldWidget.isPlaying != widget.isPlaying) {
        widget.isPlaying ? _audioPlayer!.play() : _audioPlayer!.pause();
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _isTtsMode ? _ttsPlaying : widget.isPlaying;

    final totalDur = _isTtsMode
        ? (_ttsDuration == Duration.zero
            ? const Duration(seconds: 1)
            : _ttsDuration)
        : (widget.totalDuration == Duration.zero
            ? const Duration(seconds: 1)
            : widget.totalDuration);

    final curPos = _isTtsMode ? _ttsPosition : widget.currentPosition;
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
          // TTS badge
          if (_isTtsMode)
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

          // ✅ Slider — TTS uchun ham
          SliderTheme(
            data: const SliderThemeData(
              trackHeight: 4,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: sliderVal,
              max: sliderMax,
              onChanged: _isTtsMode
                  ? null
                  : (v) => _audioPlayer?.seek(Duration(seconds: v.toInt())),
              activeColor: AppColors.primary,
              inactiveColor: Colors.grey.shade300,
            ),
          ),

          // ✅ Vaqt — doim ko'rsatiladi
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

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isTtsMode)
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
              GestureDetector(
                onTap: _isTtsMode ? _ttsPlayPause : widget.onPlayPause,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (!_isTtsMode)
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
                  if (_isTtsMode) {
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
          if (_isTtsMode) ...[
            const SizedBox(height: 4),
            Text(
              isPlaying ? '🔊 O\'qilmoqda...' : '▶ Play tugmasini bosing',
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
