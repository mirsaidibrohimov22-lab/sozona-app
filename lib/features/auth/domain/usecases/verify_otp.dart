// lib/features/auth/domain/usecases/verify_otp.dart
// So'zona — OTP tasdiqlash use case
// Telefon orqali kirish jarayonining 2-bosqichi

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';
import 'package:my_first_app/features/auth/domain/repositories/auth_repository.dart';

/// OTP kodni tasdiqlash use case
/// [verificationId] — SignInWithPhone'dan kelgan ID
/// [otpCode] — Foydalanuvchi kiritgan 6 xonali kod
class VerifyOtp implements UseCase<UserEntity, VerifyOtpParams> {
  final AuthRepository _repository;

  const VerifyOtp(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call(VerifyOtpParams params) async {
    // Verification ID tekshiruvi
    if (params.verificationId.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Tasdiqlash kodi yaroqsiz. Qaytadan urinib ko\'ring',
        ),
      );
    }

    // OTP kod tekshiruvi — 6 ta raqam
    if (params.otpCode.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Tasdiqlash kodi kiritilishi shart'),
      );
    }

    final otpRegex = RegExp(r'^\d{6}$');
    if (!otpRegex.hasMatch(params.otpCode.trim())) {
      return const Left(
        ValidationFailure(
          message: 'Tasdiqlash kodi 6 ta raqamdan iborat bo\'lishi kerak',
        ),
      );
    }

    // Repository'ga murojaat
    return _repository.verifyOtp(
      verificationId: params.verificationId.trim(),
      otpCode: params.otpCode.trim(),
    );
  }
}

/// OTP tasdiqlash parametrlari
class VerifyOtpParams extends Equatable {
  final String verificationId;
  final String otpCode;

  const VerifyOtpParams({
    required this.verificationId,
    required this.otpCode,
  });

  @override
  List<Object> get props => [verificationId, otpCode];
}
