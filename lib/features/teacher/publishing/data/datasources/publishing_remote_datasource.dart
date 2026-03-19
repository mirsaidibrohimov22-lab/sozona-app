// lib/features/teacher/publishing/data/datasources/publishing_remote_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/features/teacher/publishing/data/models/publish_schedule_model.dart';

abstract class PublishingRemoteDataSource {
  Future<void> publishContent({
    required String contentId,
    required String contentType,
    required List<String> classIds,
  });
  Future<void> scheduleContent({
    required String contentId,
    required String contentType,
    required List<String> classIds,
    required DateTime scheduledAt,
  });
  Future<List<PublishScheduleModel>> getSchedules(String teacherId);
}

class PublishingRemoteDataSourceImpl implements PublishingRemoteDataSource {
  final FirebaseFirestore _db;
  PublishingRemoteDataSourceImpl(this._db);

  @override
  Future<void> publishContent({
    required String contentId,
    required String contentType,
    required List<String> classIds,
  }) async {
    try {
      final batch = _db.batch();
      for (final classId in classIds) {
        batch.set(
            _db
                .collection('classes')
                .doc(classId)
                .collection('content')
                .doc(contentId),
            {
              'contentId': contentId,
              'contentType': contentType,
              'publishedAt': FieldValue.serverTimestamp(),
            });
      }
      batch.set(_db.collection('publishSchedules').doc(), {
        'contentId': contentId,
        'contentType': contentType,
        'classIds': classIds,
        'isPublishedNow': true,
        'status': 'published',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } catch (e) {
      throw ServerException(message: 'Nashr qilinmadi: $e');
    }
  }

  @override
  Future<void> scheduleContent({
    required String contentId,
    required String contentType,
    required List<String> classIds,
    required DateTime scheduledAt,
  }) async {
    try {
      await _db.collection('publishSchedules').add({
        'contentId': contentId,
        'contentType': contentType,
        'classIds': classIds,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'isPublishedNow': false,
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException(message: 'Jadval saqlanmadi: $e');
    }
  }

  @override
  Future<List<PublishScheduleModel>> getSchedules(String teacherId) async {
    try {
      final snap = await _db
          .collection('publishSchedules')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      return snap.docs
          .map((d) => PublishScheduleModel.fromFirestore(d.data(), d.id))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Jadvallar yuklanmadi: $e');
    }
  }
}
