// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Chat Provider
// QO'YISH: lib/features/student/ai_chat/presentation/providers/ai_chat_provider.dart
// ✅ 2-KUN FIX (K7): Greeting logikasi to'g'rilandi
//    ESKI: en → O'zbekcha, de → Nemischa (TESKARI!)
//    YANGI: en → Inglizcha, de → Nemischa, default → O'zbekcha
// ✅ 2-KUN FIX (K8): language va level user profildan olinadi
//    ESKI: language: 'en', level: 'beginner' (HARDCODE)
//    YANGI: user.learningLanguage.name, user.level.name
// ✅ 2-KUN FIX (J): chat_provider.dart re-export fayli uchun backward compat
// ═══════════════════════════════════════════════════════════════

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

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
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

  ChatNotifier({
    required SendMessage sendMessage,
    required GetChatHistory getHistory,
    required this.userId,
    required this.language,
    required this.level,
  })  : _sendMessage = sendMessage,
        _getHistory = getHistory,
        super(const ChatState()) {
    _loadHistory();
    _sendProactiveGreeting();
  }

  Future<void> _loadHistory() async {
    final result = await _getHistory(GetChatHistoryParams(userId: userId));
    result.fold(
      (failure) => null,
      (messages) => state = state.copyWith(messages: messages),
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
    language: user?.learningLanguage.name ?? 'en',
    level: user?.level.name ?? 'A1',
  );
});
