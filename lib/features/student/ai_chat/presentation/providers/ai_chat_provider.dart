// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Chat Provider
// QO'YISH: lib/features/student/ai_chat/presentation/providers/ai_chat_provider.dart
// ✅ 2-KUN FIX (K7): Greeting logikasi to'g'rilandi
//    ESKI: en → O'zbekcha, de → Nemischa (TESKARI!)
//    YANGI: en → Inglizcha, de → Nemischa, default → O'zbekcha
// ✅ 2-KUN FIX (K8): language va level user profildan olinadi
//    ESKI: language: 'en', level: 'beginner' (HARDCODE)
//    YANGI: user.learningLanguage.name, user.level.name.toUpperCase()
// ✅ 2-KUN FIX (J): chat_provider.dart re-export fayli uchun backward compat
// ═══════════════════════════════════════════════════════════════

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/providers/firebase_providers.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/ai_chat/data/datasources/chat_remote_datasource.dart';
import 'package:my_first_app/features/student/ai_chat/data/repositories/ai_chat_repository_impl.dart';
import 'package:my_first_app/features/student/ai_chat/domain/entities/chat_message.dart';
import 'package:my_first_app/features/student/ai_chat/domain/repositories/chat_repository.dart';
import 'package:my_first_app/features/student/ai_chat/domain/usecases/send_message.dart';
import 'package:my_first_app/features/student/ai_chat/domain/usecases/get_chat_history.dart';

// ─── Providers ───────────────────────────────────────────────

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  // ✅ us-central1 region — index.ts bilan mos
  return ChatRemoteDataSourceImpl(firestore);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final remote = ref.watch(chatRemoteDataSourceProvider);
  return AiChatRepositoryImpl(remoteDataSource: remote);
});

final sendMessageUseCaseProvider = Provider<SendMessage>((ref) {
  return SendMessage(ref.watch(chatRepositoryProvider));
});

final getChatHistoryUseCaseProvider = Provider<GetChatHistory>((ref) {
  return GetChatHistory(ref.watch(chatRepositoryProvider));
});

// ─── Chat State ───────────────────────────────────────────────

class ChatLimitState {
  final int used;
  final int limit;
  final int remaining;
  final bool isPremium;
  final bool isLoaded;

  const ChatLimitState({
    this.used = 0,
    this.limit = 10,
    this.remaining = 10,
    this.isPremium = false,
    this.isLoaded = false,
  });

  ChatLimitState copyWith({
    int? used,
    int? limit,
    int? remaining,
    bool? isPremium,
    bool? isLoaded,
  }) {
    return ChatLimitState(
      used: used ?? this.used,
      limit: limit ?? this.limit,
      remaining: remaining ?? this.remaining,
      isPremium: isPremium ?? this.isPremium,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final ChatLimitState limitState; // ✅ FIX: chat limit holati

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.limitState = const ChatLimitState(),
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    ChatLimitState? limitState,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      limitState: limitState ?? this.limitState,
    );
  }
}

// ─── Chat Notifier ────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  final SendMessage _sendMessage;
  final GetChatHistory _getHistory;
  final String userId;
  final String language;
  final String level;
  final FirebaseFunctions _functions; // ✅ FIX: limit yuklash uchun

  ChatNotifier({
    required SendMessage sendMessage,
    required GetChatHistory getHistory,
    required this.userId,
    required this.language,
    required this.level,
  })  : _sendMessage = sendMessage,
        _getHistory = getHistory,
        _functions = FirebaseFunctions.instanceFor(region: 'us-central1'),
        super(const ChatState()) {
    _loadHistory();
    _sendProactiveGreeting();
    _loadChatLimit(); // ✅ FIX: limit holatini yuklash
  }

  Future<void> _loadHistory() async {
    final result = await _getHistory(GetChatHistoryParams(userId: userId));
    result.fold(
      (failure) => null,
      (messages) => state = state.copyWith(messages: messages),
    );
  }

  // ✅ FIX: Cloud Function dan limit holatini yuklaymiz
  Future<void> _loadChatLimit() async {
    if (userId.isEmpty) return;
    try {
      final result = await _functions.httpsCallable('getChatStatus').call();
      final data = Map<String, dynamic>.from(result.data as Map);
      if (!mounted) return;
      state = state.copyWith(
        limitState: ChatLimitState(
          used: (data['used'] as num?)?.toInt() ?? 0,
          limit: (data['limit'] as num?)?.toInt() ?? 10,
          remaining: (data['remaining'] as num?)?.toInt() ?? 10,
          isPremium: (data['isPremium'] as bool?) ?? false,
          isLoaded: true,
        ),
      );
    } catch (_) {
      // Limit yuklanmasa ham chat ishlaydi
    }
  }

  // ✅ FIX: Xabar yuborgandan keyin limit yangilanadi
  void _decrementLimit() {
    final l = state.limitState;
    if (!l.isLoaded) return;
    state = state.copyWith(
      limitState: l.copyWith(
        used: l.used + 1,
        remaining: (l.remaining - 1).clamp(0, l.limit),
      ),
    );
  }

  // ✅ 2-KUN FIX (K7): Greeting logikasi TO'G'RILANDI
  // ESKI KOD:
  //   language == 'en' → O'zbekcha salom (XATO!)
  //   else → Nemischa salom (XATO!)
  // YANGI KOD:
  //   language == 'en' → Inglizcha salom
  //   language == 'de' → Nemischa salom
  //   default → O'zbekcha salom (ona tili)
  Future<void> _sendProactiveGreeting() async {
    if (state.messages.isNotEmpty) return;

    // ✅ Til bo'yicha to'g'ri greeting
    final String greetingText;
    switch (language) {
      case 'en':
        greetingText = 'Hello! 👋 I\'m your language learning assistant. '
            'What topic would you like to learn today?';
        break;
      case 'de':
        greetingText = 'Hallo! 👋 Ich bin Ihr Sprachlernassistent. '
            'Welches Thema möchten Sie heute lernen?';
        break;
      default:
        // O'zbekcha — default (ona tili)
        greetingText = 'Salom! 👋 Men sizning til o\'rganish yordamchingizman. '
            'Qanday mavzuni o\'rganmoqchisiz?';
    }

    final greeting = ChatMessage(
      id: 'greeting',
      text: greetingText,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(messages: [greeting]);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // User xabar qo'shish
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    // Loading placeholder
    final loadingMsg = ChatMessage(
      id: 'loading',
      text: '...',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, loadingMsg],
      isLoading: true,
      error: null,
    );

    final result = await _sendMessage(
      SendMessageChatParams(
        userId: userId,
        message: text,
        language: language,
        level: level,
        history: state.messages.where((m) => !m.isLoading).toList(),
      ),
    );

    result.fold(
      (failure) {
        // ✅ 2-KUN FIX (E): Raw error o'rniga user-friendly xabar
        final userFriendlyError = _normalizeError(failure.message);

        // Loading'ni o'chirib, xato ko'rsatish
        state = state.copyWith(
          messages: state.messages.where((m) => !m.isLoading).toList(),
          isLoading: false,
          error: userFriendlyError,
        );
      },
      (aiMessage) {
        // Loading'ni AI javob bilan almashtirish
        final updatedMessages =
            state.messages.where((m) => !m.isLoading).toList()..add(aiMessage);

        state = state.copyWith(
          messages: updatedMessages,
          isLoading: false,
        );
        // ✅ FIX: Muvaffaqiyatli javobdan keyin limit yangilanadi
        _decrementLimit();
      },
    );
  }

  /// ✅ 2-KUN FIX (E): Raw Gemini/Firebase xatosini foydalanuvchi uchun tushunarli qilish
  String _normalizeError(String error) {
    if (error.contains('429') || error.contains('Too Many Requests')) {
      return 'AI hozir band. Iltimos, bir necha daqiqadan keyin urinib ko\'ring.';
    }
    if (error.contains('quota') || error.contains('exceeded')) {
      return 'Bugungi AI so\'rovlar limiti tugadi. Ertaga qayta urinib ko\'ring.';
    }
    if (error.contains('resource-exhausted')) {
      return 'Juda ko\'p so\'rov. Biroz kutib, qaytadan urinib ko\'ring.';
    }
    if (error.contains('permission-denied') ||
        error.contains('unauthenticated')) {
      return 'Iltimos, qayta tizimga kiring.';
    }
    if (error.contains('unavailable') || error.contains('network')) {
      return 'Internet aloqasi yo\'q. Aloqani tekshiring.';
    }
    if (error.contains('timeout') || error.contains('deadline')) {
      return 'So\'rov vaqti tugadi. Qayta urinib ko\'ring.';
    }
    if (error.contains('not-found')) {
      return 'AI xizmat vaqtincha mavjud emas. Keyinroq qayta urinib ko\'ring.';
    }
    // Agar xato 80 belgidan uzun bo'lsa — qisqartirish
    if (error.length > 80) {
      return 'Kechirasiz, hozir javob bera olmayapman. Qaytadan urinib ko\'ring.';
    }
    return error;
  }

  void clearError() => state = state.copyWith(error: null);
}

// ─── Provider ─────────────────────────────────────────────────

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.user;
  final uid = user?.id ?? '';

  return ChatNotifier(
    sendMessage: ref.watch(sendMessageUseCaseProvider),
    getHistory: ref.watch(getChatHistoryUseCaseProvider),
    userId: uid,
    // ✅ 2-KUN FIX (K8): User profildan til va daraja olinadi
    // ESKI: language: 'en', level: 'beginner' (HARDCODE!)
    // YANGI: user entity dan real qiymatlar
    // ✅ FIX: 'german'/'english' (enum) → 'de'/'en' (Cloud Function API kodi)
    language: user?.learningLanguage.name == 'german' ? 'de' : 'en',
    level: user?.level.name.toUpperCase() ?? 'A1',
  );
});
