// lib/features/student/artikel/presentation/providers/artikel_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/features/student/artikel/data/datasources/artikel_local_datasource.dart';
import 'package:my_first_app/features/student/artikel/data/datasources/artikel_remote_datasource.dart';
import 'package:my_first_app/features/student/artikel/data/repositories/artikel_repository_impl.dart';
import 'package:my_first_app/features/student/artikel/domain/entities/artikel_word.dart';
import 'package:my_first_app/features/student/artikel/domain/usecases/get_artikel_words.dart';

final artikelRepositoryProvider = Provider(
  (ref) => ArtikelRepositoryImpl(
    ArtikelRemoteDataSourceImpl(FirebaseFirestore.instance),
    ArtikelLocalDataSourceImpl(),
  ),
);

final artikelWordsProvider =
    FutureProvider.family<List<ArtikelWord>, String>((ref, userId) async {
  final repo = ref.read(artikelRepositoryProvider);
  final result = await GetArtikelWords(repo)(
    GetArtikelWordsParams(userId: userId),
  );
  return result.fold((f) => throw Exception(f.message), (w) => w);
});
