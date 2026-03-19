// lib/features/teacher/analytics/presentation/providers/teacher_analytics_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/features/teacher/analytics/data/datasources/teacher_analytics_remote_datasource.dart';
import 'package:my_first_app/features/teacher/analytics/data/repositories/teacher_analytics_repository_impl.dart';
import 'package:my_first_app/features/teacher/analytics/domain/entities/teacher_analytics.dart';
import 'package:my_first_app/features/teacher/analytics/domain/usecases/get_class_analytics.dart';

final analyticsRepositoryProvider = Provider(
  (ref) => TeacherAnalyticsRepositoryImpl(
    TeacherAnalyticsRemoteDataSourceImpl(FirebaseFirestore.instance),
    FirebaseFunctions.instanceFor(region: 'us-central1'),
  ),
);

final classAnalyticsProvider =
    FutureProvider.family<ClassAnalytics, String>((ref, classId) async {
  final repo = ref.read(analyticsRepositoryProvider);
  final result = await GetClassAnalytics(repo)(classId);
  return result.fold((f) => throw Exception(f.message), (a) => a);
});

final aiAdviceProvider =
    FutureProvider.family<String, String>((ref, classId) async {
  final repo = ref.read(analyticsRepositoryProvider);
  final result = await repo.getAiTeachingAdvice(classId);
  return result.fold((f) => throw Exception(f.message), (a) => a);
});
