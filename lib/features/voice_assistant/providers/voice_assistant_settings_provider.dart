// lib/features/voice_assistant/providers/voice_assistant_settings_provider.dart
// ✅ YANGI FAYL — ovozli yordamchi sozlamalari

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/providers/core_providers.dart';

// ─── Ovoz tanlov modeli ───────────────────────────
enum SozanaVoice {
  nova, // Issiq, tabiiy ayol ovozi (default)
  shimmer, // Yumshoq, sakin ayol ovozi
}

extension SozanaVoiceExt on SozanaVoice {
  String get displayName => switch (this) {
        SozanaVoice.nova => 'Nova — Issiq va jonli',
        SozanaVoice.shimmer => 'Shimmer — Yumshoq va sakin',
      };
  String get openAiId => switch (this) {
        SozanaVoice.nova => 'nova',
        SozanaVoice.shimmer => 'shimmer',
      };
  String get emoji => switch (this) {
        SozanaVoice.nova => '🌟',
        SozanaVoice.shimmer => '🌙',
      };
}

// ─── Sozlamalar modeli ─────────────────────────────
class VoiceAssistantSettings {
  final SozanaVoice voice;
  final bool backgroundEnabled; // Fon servisi yoqilganmi

  const VoiceAssistantSettings({
    this.voice = SozanaVoice.nova,
    this.backgroundEnabled = true,
  });

  VoiceAssistantSettings copyWith({
    SozanaVoice? voice,
    bool? backgroundEnabled,
  }) =>
      VoiceAssistantSettings(
        voice: voice ?? this.voice,
        backgroundEnabled: backgroundEnabled ?? this.backgroundEnabled,
      );
}

// ─── Hive kalitlari ───────────────────────────────
const _kVoiceKey = 'sozana_voice';
const _kBgKey = 'sozana_bg_enabled';

// ─── Notifier ─────────────────────────────────────
class VoiceAssistantSettingsNotifier
    extends StateNotifier<VoiceAssistantSettings> {
  final Ref _ref;

  VoiceAssistantSettingsNotifier(this._ref)
      : super(const VoiceAssistantSettings()) {
    _load();
  }

  void _load() {
    final storage = _ref.read(localStorageServiceProvider);
    final voiceStr = storage.get<String>(_kVoiceKey);
    final bgEnabled = storage.get<bool>(_kBgKey, defaultValue: true) ?? true;

    final voice =
        voiceStr == 'shimmer' ? SozanaVoice.shimmer : SozanaVoice.nova;
    state = VoiceAssistantSettings(voice: voice, backgroundEnabled: bgEnabled);
  }

  Future<void> setVoice(SozanaVoice voice) async {
    final storage = _ref.read(localStorageServiceProvider);
    await storage.put(_kVoiceKey, voice.openAiId);
    state = state.copyWith(voice: voice);
  }

  Future<void> setBackgroundEnabled(bool value) async {
    final storage = _ref.read(localStorageServiceProvider);
    await storage.put(_kBgKey, value);
    state = state.copyWith(backgroundEnabled: value);
  }
}

// ─── Provider ─────────────────────────────────────
final voiceAssistantSettingsProvider = StateNotifierProvider<
    VoiceAssistantSettingsNotifier, VoiceAssistantSettings>(
  (ref) => VoiceAssistantSettingsNotifier(ref),
);
