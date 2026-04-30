// lib/features/referral/data/repositories/referral_repository_impl.dart
// So'zona — ReferralRepository implementatsiyasi
// Firebase xatoliklarini domain Failure ga aylantiradi

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/referral/data/datasources/referral_remote_datasource.dart';
import 'package:my_first_app/features/referral/domain/entities/referral_entity.dart';
import 'package:my_first_app/features/referral/domain/repositories/referral_repository.dart';

class ReferralRepositoryImpl implements ReferralRepository {
  final ReferralRemoteDatasource _datasource;

  const ReferralRepositoryImpl({
    required ReferralRemoteDatasource datasource,
  }) : _datasource = datasource;

  // ─────────────────────────────────────────────
  // Kod yaratish
  // ─────────────────────────────────────────────
  @override
  Future<Either<Failure, String>> generateReferralCode() async {
    try {
      final code = await _datasource.generateReferralCode();
      return Right(code);
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(message: _mapError(e)));
    } catch (e) {
      return Left(ServerFailure(message: 'Kutilmagan xatolik: $e'));
    }
  }

  // ─────────────────────────────────────────────
  // Statistika olish
  // ─────────────────────────────────────────────
  @override
  Future<Either<Failure, ReferralEntity>> getReferralStats() async {
    try {
      final stats = await _datasource.getReferralStats();
      return Right(stats);
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(message: _mapError(e)));
    } catch (e) {
      return Left(ServerFailure(message: 'Kutilmagan xatolik: $e'));
    }
  }

  // ─────────────────────────────────────────────
  // Kodni qo'llash
  // ─────────────────────────────────────────────
  @override
  Future<Either<Failure, RedeemResultEntity>> redeemReferralCode(
    String code,
  ) async {
    try {
      final result = await _datasource.redeemReferralCode(code);
      return Right(result);
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(message: _mapError(e)));
    } catch (e) {
      return Left(ServerFailure(message: 'Kutilmagan xatolik: $e'));
    }
  }

  // ─────────────────────────────────────────────
  // Firebase xatoliklarini o'zbekchaga tarjima qilish
  // ─────────────────────────────────────────────
  String _mapError(FirebaseFunctionsException e) {
    return switch (e.code) {
      'unauthenticated' => 'Tizimga kiring.',
      'not-found' => e.message ?? 'Topilmadi.',
      'already-exists' => "Siz allaqachon referral kodi qo'llagansiz.",
      'failed-precondition' => "O'z kodingizni qo'llab bo'lmaydi.",
      'resource-exhausted' => "Bu kod o'z limitiga yetdi.",
      'invalid-argument' => "Kod formati noto'g'ri. Namuna: SZ-ABCD-1234",
      _ => e.message ?? 'Server xatoligi yuz berdi.',
    };
  }
}
