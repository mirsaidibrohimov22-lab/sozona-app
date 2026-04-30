// lib/features/student/ai_chat/presentation/screens/ai_chat_screen.dart
// So'zona — AI Chat Screen
// ✅ YANGI: initialMessage parametri — kitob mashqlaridan xatolar yuboriladi

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/features/student/ai_chat/domain/entities/chat_message.dart';
import 'package:my_first_app/features/student/ai_chat/presentation/providers/ai_chat_provider.dart';
import 'package:my_first_app/features/student/ai_chat/presentation/widgets/chat_bubble.dart';
import 'package:my_first_app/features/student/ai_chat/presentation/widgets/suggestion_chip.dart';
import 'package:my_first_app/features/student/ai_chat/presentation/widgets/typing_indicator.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  // ✅ YANGI: Kitob mashqlaridan xato yuborilganda avtomatik xabar
  final String? initialMessage;

  const AiChatScreen({super.key, this.initialMessage});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _initialSent = false;

  static const _suggestions = [
    'Present Perfect tushuntir',
    'Kecha/bugun/ertaga farqi',
    'Modal verbs misollar',
    'German Artikel qoidasi',
  ];

  @override
  void initState() {
    super.initState();
    // ✅ Kitobdan xato yuborilgan bo'lsa — avtomatik jo'natish
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      Future.microtask(() => _sendInitial());
    }
  }

  Future<void> _sendInitial() async {
    if (_initialSent) return;
    _initialSent = true;
    await ref.read(chatProvider.notifier).sendMessage(widget.initialMessage!);
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    await ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    if (chatState.messages.isNotEmpty) _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.smart_toy,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Yordam', style: TextStyle(fontSize: 16)),
                Builder(builder: (context) {
                  final limit = ref.watch(chatProvider).limitState;
                  if (!limit.isLoaded) {
                    return const Text('Doim tayyor',
                        style: TextStyle(fontSize: 11));
                  }
                  final color = limit.remaining <= 2
                      ? Colors.red
                      : limit.remaining <= 5
                          ? Colors.orange
                          : Colors.green;
                  return Text(
                    limit.isPremium
                        ? '${limit.remaining}/${limit.limit} (Premium)'
                        : '${limit.remaining}/${limit.limit} savol qoldi',
                    style: TextStyle(fontSize: 11, color: color),
                  );
                }),
              ],
            ),
          ],
        ),
        // ✅ Kitobdan kelgan bo'lsa — banner ko'rsatish
        bottom: widget.initialMessage != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(36),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_stories,
                          color: Color(0xFFFFD700), size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Kitob mashqlari — xatolaringiz tahlil qilinmoqda',
                        style:
                            TextStyle(color: Color(0xFFFFD700), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // Error banner
          if (chatState.error != null)
            Container(
              width: double.infinity,
              color: Colors.red[50],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatState.error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () =>
                        ref.read(chatProvider.notifier).clearError(),
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatState.messages[index];
                      if (msg.isLoading) return const TypingIndicator();
                      return ChatBubble(
                        message: msg,
                        onSuggestionTap: (text) => _send(text),
                      );
                    },
                  ),
          ),

          // Suggestions
          if (chatState.messages.isEmpty ||
              (chatState.messages.isNotEmpty &&
                  chatState.messages.last.role == MessageRole.assistant &&
                  (chatState.messages.last.suggestions.isEmpty != false) &&
                  !chatState.messages.last.isLoading))
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => SuggestionChipWidget(
                  label: _suggestions[index],
                  onTap: () => _send(_suggestions[index]),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Input bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Savolingizni yozing...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    child: chatState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: () => _send(_controller.text),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'AI Yordam',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Til o\'rganishda savollaringizga javob beraman',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
