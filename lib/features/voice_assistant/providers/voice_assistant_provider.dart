// lib/features/voice_assistant/providers/voice_assistant_provider.dart
// ✅ v2 — Cloud Function orqali, user key kiritmasin

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/premium/presentation/providers/premium_provider.dart';
import 'package:my_first_app/features/voice_assistant/providers/voice_assistant_settings_provider.dart';
import 'package:my_first_app/features/voice_assistant/services/voice_assistant_service.dart';

// ─── UI State ─────────────────────────────────────
class VoiceAssistantUiState {
  final VoiceAssistantState assistantState;
  final String displayText;
  final bool isPremium;
  final String userName;

  const VoiceAssistantUiState({
    this.assistantState = VoiceAssistantState.inactive,
    this.displayText = '',
    this.isPremium = false,
    this.userName = '',
  });

  VoiceAssistantUiState copyWith({
    VoiceAssistantState? assistantState,
    String? displayText,
    bool? isPremium,
    String? userName,
  }) =>
      VoiceAssistantUiState(
        assistantState: assistantState ?? this.assistantState,
        displayText: displayText ?? this.displayText,
        isPremium: isPremium ?? this.isPremium,
        userName: userName ?? this.userName,
      );

  bool get isListening => assistantState == VoiceAssistantState.listening;
  bool get isSpeaking => assistantState == VoiceAssistantState.speaking;
  bool get isWaitingInput => assistantState == VoiceAssistantState.waitingInput;
  bool get isActive =>
      assistantState != VoiceAssistantState.inactive &&
      assistantState != VoiceAssistantState.listening &&
      assistantState != VoiceAssistantState.keyMissing;
}

// ─── Notifier ─────────────────────────────────────
class VoiceAssistantNotifier extends StateNotifier<VoiceAssistantUiState> {
  VoiceAssistantService? _service;
  final Ref _ref;

  VoiceAssistantNotifier(this._ref) : super(const VoiceAssistantUiState());

  Future<void> initialize() async {
    final user = _ref.read(authNotifierProvider).user;
    final hasPremium = _ref.read(hasPremiumProvider);
    final settings = _ref.read(voiceAssistantSettingsProvider);

    if (user == null) return;

    _service?.removeListener(_sync);
    _service?.dispose();

    _service = VoiceAssistantService(
      userName: user.displayName.isNotEmpty ? user.displayName : "Do'stim",
      isPremium: hasPremium,
      voice: settings.voice,
      backgroundEnabled: settings.backgroundEnabled,
    );
    _service!.addListener(_sync);

    state = state.copyWith(isPremium: hasPremium, userName: user.displayName);
    await _service!.initialize();
  }

  Future<void> reinitialize() async {
    _service?.removeListener(_sync);
    await _service?.stop();
    _service?.dispose();
    _service = null;
    await initialize();
  }

  void _sync() {
    if (_service == null || !mounted) return;
    state = state.copyWith(
      assistantState: _service!.state,
      displayText: _service!.displayText,
    );
  }

  Future<void> triggerManually() async => _service?.triggerManually();
  Future<void> stop() async => _service?.stop();

  @override
  void dispose() {
    _service?.removeListener(_sync);
    _service?.dispose();
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────
final voiceAssistantProvider =
    StateNotifierProvider<VoiceAssistantNotifier, VoiceAssistantUiState>(
  (ref) => VoiceAssistantNotifier(ref),
);
