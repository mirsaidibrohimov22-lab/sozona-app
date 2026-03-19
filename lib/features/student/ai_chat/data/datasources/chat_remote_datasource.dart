// lib/features/student/ai_chat/data/datasources/chat_remote_datasource.dart
// So'zona — AI Chat Remote DataSource
// ✅ AI FALLBACK: Cloud Functions ishlamasa → mock javob qaytariladi
// ✅ App hech qachon crash bo'lmaydi

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:my_first_app/core/constants/api_endpoints.dart';
import 'package:my_first_app/features/student/ai_chat/domain/entities/chat_message.dart';

abstract class ChatRemoteDataSource {
  Future<ChatMessage> sendMessage({
    required String userId,
    required String text,
    required String language,
  });
  Future<List<ChatMessage>> getHistory(String userId);
  Future<void> clearHistory(String userId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore _db;

  ChatRemoteDataSourceImpl(this._db);

  // ✅ Region to'g'ri: index.ts da functions.region('us-central1') ishlatilgan
  static FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'us-central1');

  CollectionReference _chatCollection(String userId) =>
      _db.collection('users').doc(userId).collection('chatHistory');

  // ═══════════════════════════════════════════════════════════════
  // MOCK RESPONSES — AI ishlamasa ishlatiladi
  // ═══════════════════════════════════════════════════════════════

  static const _mockResponses = [
    'AI funksiyasi hozir ishlab chiqilmoqda. Tez orada to\'liq javob bera olaman! 🚀',
    'Salom! AI tizimi sozlanmoqda. Keyinroq bu yerda sizga ingliz va nemis tilini o\'rgataman.',
    'Rahmat savolingiz uchun! AI xizmati yaqinda ishga tushadi.',
    'Hozircha AI javob bera olmayapti. Lekin siz mashq qilishni davom ettirishingiz mumkin!',
  ];

  static int _mockIndex = 0;

  ChatMessage _buildMockResponse(String userId) {
    final reply = _mockResponses[_mockIndex % _mockResponses.length];
    _mockIndex++;
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: reply,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      suggestions: [
        'Vocabulary o\'rganish',
        'Grammar mashq',
        'Speaking practice',
      ],
      grammarTip: null,
      detectedTopic: null,
    );
  }

  // ═══════════════════════════════════════════════════════════════

  @override
  Future<ChatMessage> sendMessage({
    required String userId,
    required String text,
    required String language,
  }) async {
    try {
      final history = await getHistory(userId);

      final callable = _functions.httpsCallable(
        ApiEndpoints.chatWithAI,
        options: HttpsCallableOptions(timeout: ApiEndpoints.longTimeout),
      );

      final result = await callable.call({
        'message': text,
        'language': language,
        'history': history
            .take(10)
            .map((m) => {
                  'role': m.isUser ? 'user' : 'assistant',
                  'content': m.text,
                })
            .toList(),
      });

      final data = result.data as Map<String, dynamic>;
      final reply = data['reply'] as String? ?? '...';
      final suggestions = List<String>.from(data['suggestions'] ?? []);
      final grammarTip = data['grammarTip'] as String?;
      final detectedTopic = data['detectedTopic'] as String?;

      final aiMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: reply,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        suggestions: suggestions,
        grammarTip: grammarTip,
        detectedTopic: detectedTopic,
      );

      // Firestore ga saqlash
      final batch = _db.batch();
      final chatRef = _chatCollection(userId);
      batch.set(chatRef.doc(), {
        'text': text,
        'isUser': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(chatRef.doc(), {
        'text': reply,
        'isUser': false,
        'suggestions': suggestions,
        'grammarTip': grammarTip,
        'detectedTopic': detectedTopic,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      return aiMsg;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('⚠️ Chat AI xatosi: ${e.code} — mock javob qaytariladi');

      // Foydalanuvchi xabarini Firestore ga saqlash (AI javobsiz ham)
      try {
        final chatRef = _chatCollection(userId);
        final mock = _buildMockResponse(userId);
        final batch = _db.batch();
        batch.set(chatRef.doc(), {
          'text': text,
          'isUser': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        batch.set(chatRef.doc(), {
          'text': mock.text,
          'isUser': false,
          'suggestions': mock.suggestions,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await batch.commit();
        return mock;
      } catch (_) {
        return _buildMockResponse(userId);
      }
    } catch (e) {
      debugPrint('⚠️ Chat xatosi: $e — mock javob qaytariladi');
      return _buildMockResponse(userId);
    }
  }

  @override
  Future<List<ChatMessage>> getHistory(String userId) async {
    try {
      final snap = await _chatCollection(userId)
          .orderBy('createdAt', descending: false)
          .limit(20)
          .get();

      return snap.docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        return ChatMessage(
          id: doc.id,
          text: d['text'] as String? ?? '',
          role: (d['isUser'] as bool? ?? false)
              ? MessageRole.user
              : MessageRole.assistant,
          timestamp: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          suggestions: List<String>.from(d['suggestions'] ?? []),
          grammarTip: d['grammarTip'] as String?,
          detectedTopic: d['detectedTopic'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> clearHistory(String userId) async {
    try {
      final snap = await _chatCollection(userId).limit(100).get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('⚠️ Chat history o\'chirish xatosi: $e');
    }
  }
}
