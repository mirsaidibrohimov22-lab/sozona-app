// lib/features/auth/domain/usecases/get_current_user.dart
// So'zona — Hozirgi foydalanuvchini olish use case
// Splash screen va auth guard'da ishlatiladi
// ✅ FIX: forceServer: true — ilovani ochganda premium holati cache'dan emas
//         Firestore server'dan o'qiladi. Cache'da isPremium: false qolib ketsa
//         premium funksiyalar bloklanardi. Offline bo'lsa — cache fallback ishlaydi.

import 'package:dartz/dartz.dart';

import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';
import 'package:my_first_app/features/auth/domain/repositories/auth_repository.dart';

/// Hozirgi foydalanuvchini olish use case
/// Kirgan bo'lsa UserEntity, aks holda null qaytaradi
class GetCurrentUser implements UseCase<UserEntity?, NoParams> {
  final AuthRepository _repository;

  const GetCurrentUser(this._repository);

  @override
  Future<Either<Failure, UserEntity?>> call(NoParams params) async {
    // forceServer: true — isPremium, daraja va boshqa ma'lumotlar
    // har doim serverdan o'qiladi. Offline bo'lsa auth_repository_impl
    // avtomatik cache'ga qaytadi — xavfsiz.
    return _repository.getCurrentUser(forceServer: true);
  }
}
