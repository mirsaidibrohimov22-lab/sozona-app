// lib/features/auth/domain/repositories/auth_repository.dart
// So'zona — Auth repository interfeysi (shartnoma)
// Clean Architecture: Domain layer — faqat shartnoma, implementatsiya Data layerda

import 'package:dartz/dartz.dart';

import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';

/// Auth repository interfeysi
/// Data layer bu interfeysni implement qiladi
abstract class AuthRepository {
  /// Email va parol bilan kirish
  /// [email] — foydalanuvchi emaili
  /// [password] — foydalanuvchi paroli
  /// Muvaffaqiyatli bo'lsa [UserEntity] qaytaradi
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Telefon raqami bilan OTP yuborish
  /// [phoneNumber] — telefon raqami (+998 bilan)
  /// Muvaffaqiyatli bo'lsa verification ID qaytaradi
  Future<Either<Failure, String>> signInWithPhone({
    required String phoneNumber,
  });

  /// OTP kodni tasdiqlash
  /// [verificationId] — Firebase'dan kelgan ID
  /// [otpCode] — 6 xonali kod
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String verificationId,
    required String otpCode,
  });

  /// Yangi hisob yaratish (email + parol)
  /// [displayName] — foydalanuvchi ismi
  /// [email] — elektron pochta
  /// [password] — parol (kamida 8 belgi)
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String displayName,
    required String email,
    required String password,
  });

  /// Tizimdan chiqish
  Future<Either<Failure, void>> signOut();

  /// Hozirgi foydalanuvchini olish
  /// Agar kirgan bo'lsa [UserEntity], aks holda null
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Parolni tiklash uchun email yuborish
  /// [email] — foydalanuvchi emaili
  Future<Either<Failure, void>> resetPassword({
    required String email,
  });

  /// Foydalanuvchi profilini yangilash (setup profile)
  /// [user] — yangilangan foydalanuvchi ma'lumotlari
  Future<Either<Failure, UserEntity>> updateProfile({
    required UserEntity user,
  });

  /// Auth holatini kuzatish (stream)
  /// Kirish/chiqishda avtomatik yangilanadi
  Stream<UserEntity?> get authStateChanges;

  /// Email tasdiqlangan yoki yo'qligini tekshirish
  Future<Either<Failure, bool>> isEmailVerified();

  /// Email tasdiqlash xabarini qayta yuborish
  Future<Either<Failure, void>> resendEmailVerification();
}
