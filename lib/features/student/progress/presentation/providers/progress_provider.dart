// lib/features/student/progress/presentation/providers/progress_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/features/student/progress/data/datasources/progress_remote_datasource.dart';
import 'package:my_first_app/features/student/progress/data/repositories/progress_repository_impl.dart';
import 'package:my_first_app/features/student/progress/domain/entities/progress.dart';
import 'package:my_first_app/features/student/progress/domain/usecases/get_progress.dart';

final progressRepositoryProvider = Provider((ref) {
  final ds = ProgressRemoteDataSourceImpl(FirebaseFirestore.instance);
  return ProgressRepositoryImpl(ds);
});

final progressProvider =
    FutureProvider.family<UserProgress, String>((ref, uid) async {
  final repo = ref.read(progressRepositoryProvider);
  final result = await GetProgress(repo)(uid);
  return result.fold((f) => throw Exception(f.message), (p) => p);
});
