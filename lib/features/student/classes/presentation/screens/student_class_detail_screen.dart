// lib/features/student/classes/presentation/screens/student_class_detail_screen.dart
// Sinf ichidagi ekran — kontentlar ro'yxati + chat

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/providers/firebase_providers.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/core/widgets/app_loading_widget.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/teacher/classes/presentation/providers/class_provider.dart';

// ─── Provider: Sinf kontentlarini olish ───
final classContentProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, classId) {
  final db = ref.watch(firestoreProvider);
  return db
      .collection('classes')
      .doc(classId)
      .collection('content')
      // orderBy olib tashlandi — Firestore index kerak emas
      // Dart tomonida sort qilamiz
      .snapshots()
      .map((snap) {
    final list = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    // ✅ publishedAt Timestamp bo'lishi mumkin — to'g'ri sort
    list.sort((a, b) {
      DateTime? aTime;
      DateTime? bTime;

      final aRaw = a['publishedAt'];
      final bRaw = b['publishedAt'];

      if (aRaw is Timestamp) aTime = aRaw.toDate();
      if (bRaw is Timestamp) bTime = bRaw.toDate();

      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime); // yangi avval
    });
    return list;
  });
});

// ─── Provider: Sinf chat xabarlarini olish ───
final classChatProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, classId) {
  final db = ref.watch(firestoreProvider);
  return db
      .collection('classes')
      .doc(classId)
      .collection('chat')
      // ✅ limitToLast uchun orderBy shart — olib tashlab bo'lmaydi
      .orderBy('createdAt')
      .limitToLast(50)
      .snapshots()
      .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

class StudentClassDetailScreen extends ConsumerStatefulWidget {
  final String classId;

  const StudentClassDetailScreen({super.key, required this.classId});

  @override
  ConsumerState<StudentClassDetailScreen> createState() =>
      _StudentClassDetailScreenState();
}

class _StudentClassDetailScreenState
    extends ConsumerState<StudentClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Chat xabar yuborish
  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isSending) return;

    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    setState(() => _isSending = true);
    _chatController.clear();

    try {
      final db = ref.read(firestoreProvider);
      await db
          .collection('classes')
          .doc(widget.classId)
          .collection('chat')
          .add({
        'text': text,
        'senderId': user.id,
        'senderName': user.displayName,
        'senderRole': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Pastga scroll
      await Future.delayed(const Duration(milliseconds: 300));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xabar yuborilmadi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(studentClassesProvider).valueOrNull ?? [];
    final schoolClass =
        classes.where((c) => c.id == widget.classId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(schoolClass?.name ?? 'Sinf'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.assignment_outlined), text: 'Kontentlar'),
            Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chat'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ContentTab(classId: widget.classId),
          _ChatTab(
            classId: widget.classId,
            chatController: _chatController,
            scrollController: _scrollController,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// KONTENT TAB
// ══════════════════════════════════════════════════

class _ContentTab extends ConsumerWidget {
  final String classId;

  const _ContentTab({required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(classContentProvider(classId));

    return contentAsync.when(
      loading: () => const AppLoadingWidget(),
      error: (e, _) => Center(child: Text('Xatolik: $e')),
      data: (contents) {
        if (contents.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined,
                    size: 64, color: AppColors.textTertiary),
                SizedBox(height: 16),
                Text(
                  'Hozircha kontent yo\'q',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'O\'qituvchi kontent yuborishini kuting',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: contents.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _ContentCard(
              content: contents[index],
              onTap: () => _openContent(context, contents[index]),
            );
          },
        );
      },
    );
  }

  // Kontentga bosilganda tegishli bo'limga yo'naltirish
  void _openContent(BuildContext context, Map<String, dynamic> content) {
    final type = content['type'] as String? ?? '';
    final contentId = content['id'] as String? ?? '';

    // ✅ ID bilan navigate qilamiz — kontent endi root content collectionida ham bor
    switch (type) {
      case 'quiz':
        context.push('/student/quiz/$contentId');
        break;
      case 'listening':
        context.push('/student/listening/$contentId');
        break;
      case 'speaking':
        context.push('/student/speaking/$contentId');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$type turi tez orada qo\'shiladi')),
        );
    }
  }
}

class _ContentCard extends StatelessWidget {
  final Map<String, dynamic> content;
  final VoidCallback onTap;

  const _ContentCard({required this.content, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = content['type'] as String? ?? '';
    final topic = content['topic'] as String? ?? '';
    final level = content['level'] as String? ?? '';
    final language = content['language'] as String? ?? 'en';

    final typeInfo = _getTypeInfo(type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Tur ikonkasi
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: typeInfo['color'] as Color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  typeInfo['emoji'] as String,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Ma'lumot
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.isNotEmpty ? topic : typeInfo['label'] as String,
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Tag(typeInfo['label'] as String),
                      const SizedBox(width: 6),
                      _Tag(level),
                      const SizedBox(width: 6),
                      _Tag(language == 'en' ? '🇬🇧' : '🇩🇪'),
                    ],
                  ),
                ],
              ),
            ),
            // O'q
            const Icon(
              Icons.play_circle_outline,
              color: AppColors.primary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getTypeInfo(String type) {
    switch (type) {
      case 'quiz':
        return {
          'emoji': '🧠',
          'label': 'Quiz',
          'color': const Color(0xFFEDE9FE),
        };
      case 'listening':
        return {
          'emoji': '🎧',
          'label': 'Listening',
          'color': const Color(0xFFE0F2FE),
        };
      case 'speaking':
        return {
          'emoji': '🗣️',
          'label': 'Speaking',
          'color': const Color(0xFFDCFCE7),
        };
      default:
        return {
          'emoji': '📝',
          'label': type,
          'color': const Color(0xFFF3F4F6),
        };
    }
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// CHAT TAB
// ══════════════════════════════════════════════════

class _ChatTab extends ConsumerWidget {
  final String classId;
  final TextEditingController chatController;
  final ScrollController scrollController;
  final bool isSending;
  final VoidCallback onSend;

  const _ChatTab({
    required this.classId,
    required this.chatController,
    required this.scrollController,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatAsync = ref.watch(classChatProvider(classId));
    final currentUser = ref.watch(authNotifierProvider).user;

    return Column(
      children: [
        // Xabarlar ro'yxati
        Expanded(
          child: chatAsync.when(
            loading: () => const AppLoadingWidget(),
            error: (e, _) => Center(child: Text('Xatolik: $e')),
            data: (messages) {
              if (messages.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 64, color: AppColors.textTertiary),
                      SizedBox(height: 16),
                      Text(
                        'Hali xabar yo\'q',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Birinchi xabarni yuboring!',
                        style: TextStyle(
                            color: AppColors.textTertiary, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg['senderId'] == currentUser?.id;
                  return _ChatBubble(message: msg, isMe: isMe);
                },
              );
            },
          ),
        ),

        // Xabar yozish maydoni
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: chatController,
                    decoration: InputDecoration(
                      hintText: 'Xabar yozing...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: AppColors.bgTertiary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                // Yuborish tugmasi
                GestureDetector(
                  onTap: isSending ? null : onSend,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSending ? Colors.grey : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: isSending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;

  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final text = message['text'] as String? ?? '';
    final senderName = message['senderName'] as String? ?? '';
    final senderRole = message['senderRole'] as String? ?? 'student';
    final isTeacher = senderRole == 'teacher';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Boshqa odam avatari
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  isTeacher ? AppColors.primary : AppColors.primaryContainer,
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: isTeacher ? Colors.white : AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Xabar pufakchasi
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Ism (boshqa odam uchun)
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      isTeacher ? '👨‍🏫 $senderName' : senderName,
                      style: AppTextStyles.caption.copyWith(
                        color: isTeacher
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: isTeacher ? FontWeight.w600 : null,
                      ),
                    ),
                  ),

                // Xabar matni
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primary
                        : isTeacher
                            ? const Color(0xFFEDE9FE)
                            : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border:
                        isMe ? null : Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
