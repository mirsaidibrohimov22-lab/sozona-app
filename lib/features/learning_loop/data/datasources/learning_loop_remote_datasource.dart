// QO'YISH: lib/features/learning_loop/data/datasources/learning_loop_remote_datasource.dart
// So'zona — Learning Loop Firebase datasource

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/features/learning_loop/data/models/learner_profile_model.dart';
import 'package:my_first_app/features/learning_loop/data/models/micro_session_model.dart';
import 'package:my_first_app/features/learning_loop/data/models/weak_item_pool_model.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/micro_session.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/weak_item_pool.dart';
import 'package:uuid/uuid.dart';

abstract class LearningLoopRemoteDataSource {
  Future<List<WeakItemModel>> getWeakItems(String userId);
  Future<List<WeakItemModel>> getDueWeakItems(String userId);
  Future<WeakItemModel> addWeakItem({
    required String userId,
    required WeakItemSource sourceType,
    required String sourceContentId,
    required String itemType,
    required WeakItemData itemData,
  });
  Future<WeakItemModel> updateWeakItem(WeakItemModel item);
  Future<List<WeakItemModel>> batchUpdateWeakItems(List<WeakItemModel> items);
  Future<LearnerProfileModel> getLearnerProfile(String userId);
  Future<LearnerProfileModel> updateLearnerProfile(LearnerProfileModel profile);
  Future<LearnerProfileModel> analyzeAndUpdateProfile({
    required String userId,
    required String language,
    required String level,
  });
  Future<MicroSessionModel> getOrCreateNextSession(String userId);
  Future<MicroSessionModel> startSession(String sessionId, String userId);
  Future<MicroSessionModel> completeSession({
    required String sessionId,
    required String userId,
    required int overallScore,
    required int weakItemsReviewed,
    required int newWeakItems,
    required int xpEarned,
    String? motivationMessage,
  });
  Future<MicroSessionModel> skipSession(String sessionId, String userId);
  Future<List<MicroSessionModel>> getSessionHistory({
    required String userId,
    int limit = 20,
  });
  Future<String> getMotivationMessage({
    required String userId,
    required int currentStreak,
    required double averageScore,
    required String language,
  });
}

class LearningLoopRemoteDataSourceImpl implements LearningLoopRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final _uuid = const Uuid();

  LearningLoopRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  })  : _firestore = firestore,
        _functions = functions;

  // ─── Weak Items ───

  @override
  Future<List<WeakItemModel>> getWeakItems(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('weakItems')
          .where('status', isEqualTo: 'active')
          .orderBy('nextReviewAt')
          .limit(100)
          .get();

      return snapshot.docs.map(WeakItemModel.fromFirestore).toList();
    } catch (e) {
      throw ServerException(message: 'Zaif elementlar yuklanmadi: $e');
    }
  }

  @override
  Future<List<WeakItemModel>> getDueWeakItems(String userId) async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('weakItems')
          .where('status', isEqualTo: 'active')
          .where('nextReviewAt', isLessThanOrEqualTo: now)
          .orderBy('nextReviewAt')
          .limit(20)
          .get();

      return snapshot.docs.map(WeakItemModel.fromFirestore).toList();
    } catch (e) {
      throw ServerException(message: 'Zaif elementlar yuklanmadi: $e');
    }
  }

  @override
  Future<WeakItemModel> addWeakItem({
    required String userId,
    required WeakItemSource sourceType,
    required String sourceContentId,
    required String itemType,
    required WeakItemData itemData,
  }) async {
    try {
      final now = DateTime.now();
      final item = WeakItemModel(
        id: _uuid.v4(),
        userId: userId,
        sourceType: sourceType,
        sourceContentId: sourceContentId,
        itemType: itemType,
        itemData: itemData,
        nextReviewAt: now.add(const Duration(days: 1)),
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('weakItems')
          .doc(item.id)
          .set(item.toFirestore());

      return item;
    } catch (e) {
      throw ServerException(message: 'Zaif element qo\'shilmadi: $e');
    }
  }

  @override
  Future<WeakItemModel> updateWeakItem(WeakItemModel item) async {
    try {
      await _firestore
          .collection('users')
          .doc(item.userId)
          .collection('weakItems')
          .doc(item.id)
          .update(item.toFirestore());
      return item;
    } catch (e) {
      throw ServerException(message: 'Zaif element yangilanmadi: $e');
    }
  }

  @override
  Future<List<WeakItemModel>> batchUpdateWeakItems(
    List<WeakItemModel> items,
  ) async {
    if (items.isEmpty) return [];
    try {
      final batch = _firestore.batch();
      for (final item in items) {
        final ref = _firestore
            .collection('users')
            .doc(item.userId)
            .collection('weakItems')
            .doc(item.id);
        batch.update(ref, item.toFirestore());
      }
      await batch.commit();
      return items;
    } catch (e) {
      throw ServerException(message: 'Batch yangilash xatoligi: $e');
    }
  }

  // ─── Learner Profile ───

  @override
  Future<LearnerProfileModel> getLearnerProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('learnerProfile')
          .doc('current')
          .get();

      if (!doc.exists) {
        final initial = LearnerProfileModel.initial(userId);
        await updateLearnerProfile(initial);
        return initial;
      }

      return LearnerProfileModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException(message: 'Profil yuklanmadi: $e');
    }
  }

  @override
  Future<LearnerProfileModel> updateLearnerProfile(
    LearnerProfileModel profile,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.userId)
          .collection('learnerProfile')
          .doc('current')
          .set(profile.toFirestore(), SetOptions(merge: true));
      return profile;
    } catch (e) {
      throw ServerException(message: 'Profil yangilanmadi: $e');
    }
  }

  @override
  Future<LearnerProfileModel> analyzeAndUpdateProfile({
    required String userId,
    required String language,
    required String level,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'analyzeWeakness',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      await callable.call({
        'userId': userId,
        'language': language,
        'level': level,
      });

      // AI analysis result used to update profile on server side
      final profile = await getLearnerProfile(userId);
      return profile;
    } on FirebaseFunctionsException catch (e) {
      throw ServerException(message: 'AI tahlil xatoligi: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Profil tahlil xatoligi: $e');
    }
  }

  // ─── Micro Sessions ───

  @override
  Future<MicroSessionModel> getOrCreateNextSession(String userId) async {
    try {
      // Mavjud rejalashtirilgan sessiyani qidirish
      final snapshot = await _firestore
          .collection('microSessions')
          .doc(userId)
          .collection('sessions')
          .where('status', isEqualTo: 'scheduled')
          .orderBy('scheduledAt')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return MicroSessionModel.fromFirestore(snapshot.docs.first);
      }

      // Yangi sessiya yaratish
      return _createNextSession(userId);
    } catch (e) {
      throw ServerException(message: 'Sessiya yuklanmadi: $e');
    }
  }

  Future<MicroSessionModel> _createNextSession(String userId) async {
    final now = DateTime.now();

    // Oxirgi sessiya turini olish (navbatma-navbat)
    final lastSnapshot = await _firestore
        .collection('microSessions')
        .doc(userId)
        .collection('sessions')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    SessionType nextType = SessionType.flashcardQuiz;
    if (lastSnapshot.docs.isNotEmpty) {
      final lastData = lastSnapshot.docs.first.data();
      final lastType = lastData['sessionType'] as String? ?? 'flashcardQuiz';
      // Navbatma-navbat
      nextType = lastType == 'flashcardQuiz'
          ? SessionType.listeningSpeaking
          : SessionType.flashcardQuiz;
    }

    final session = MicroSessionModel(
      id: _uuid.v4(),
      userId: userId,
      sessionType: nextType,
      scheduledAt: now,
      createdAt: now,
    );

    await _firestore
        .collection('microSessions')
        .doc(userId)
        .collection('sessions')
        .doc(session.id)
        .set(session.toFirestore());

    return session;
  }

  @override
  Future<MicroSessionModel> startSession(
    String sessionId,
    String userId,
  ) async {
    try {
      final ref = _firestore
          .collection('microSessions')
          .doc(userId)
          .collection('sessions')
          .doc(sessionId);

      await ref.update({
        'status': 'inProgress',
        'startedAt': Timestamp.fromDate(DateTime.now()),
      });

      final doc = await ref.get();
      return MicroSessionModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException(message: 'Sessiya boshlanmadi: $e');
    }
  }

  @override
  Future<MicroSessionModel> completeSession({
    required String sessionId,
    required String userId,
    required int overallScore,
    required int weakItemsReviewed,
    required int newWeakItems,
    required int xpEarned,
    String? motivationMessage,
  }) async {
    try {
      final now = DateTime.now();
      final ref = _firestore
          .collection('microSessions')
          .doc(userId)
          .collection('sessions')
          .doc(sessionId);

      await ref.update({
        'status': 'completed',
        'completedAt': Timestamp.fromDate(now),
        'overallScore': overallScore,
        'weakItemsReviewed': weakItemsReviewed,
        'newWeakItems': newWeakItems,
        'xpEarned': xpEarned,
        'motivationMessage': motivationMessage,
      });

      final doc = await ref.get();
      return MicroSessionModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException(message: 'Sessiya tugatilmadi: $e');
    }
  }

  @override
  Future<MicroSessionModel> skipSession(String sessionId, String userId) async {
    try {
      final ref = _firestore
          .collection('microSessions')
          .doc(userId)
          .collection('sessions')
          .doc(sessionId);

      await ref.update({'status': 'skipped'});
      final doc = await ref.get();
      return MicroSessionModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException(message: 'Sessiya o\'tkazib yuborilmadi: $e');
    }
  }

  @override
  Future<List<MicroSessionModel>> getSessionHistory({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('microSessions')
          .doc(userId)
          .collection('sessions')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(MicroSessionModel.fromFirestore).toList();
    } catch (e) {
      throw ServerException(message: 'Sessiya tarixi yuklanmadi: $e');
    }
  }

  @override
  Future<String> getMotivationMessage({
    required String userId,
    required int currentStreak,
    required double averageScore,
    required String language,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'getMotivationMessage',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
      );

      final result = await callable.call({
        'userId': userId,
        'currentStreak': currentStreak,
        'averageScore': averageScore,
        'language': language,
      });

      final data = result.data as Map<String, dynamic>;
      return data['message'] as String? ?? '';
    } catch (e) {
      throw ServerException(message: 'Motivatsiya xabari yuklanmadi: $e');
    }
  }
}
