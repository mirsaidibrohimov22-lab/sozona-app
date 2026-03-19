// lib/features/auth/domain/usecases/sign_in_with_phone.dart
// So'zona — Telefon bilan kirish use case
// OTP yuborish bosqichi — verification ID qaytaradi

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/auth/domain/repositories/auth_repository.dart';

/// Telefon raqami bilan OTP yuborish use case
/// Natija: verificationId (String) — OTP tasdiqlash uchun kerak
class SignInWithPhone implements UseCase<String, SignInWithPhoneParams> {
  final AuthRepository _repository;

  const SignInWithPhone(this._repository);

  @override
  Future<Either<Failure, String>> call(SignInWithPhoneParams params) async {
    // Telefon raqami validatsiya
    if (params.phoneNumber.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Telefon raqami kiritilishi shart'),
      );
    }

    // Telefon raqami formati tekshiruvi
    // +998 bilan boshlanishi va 12 ta raqam bo'lishi kerak
    final phoneRegex = RegExp(r'^\+\d{10,15}$');
    if (!phoneRegex.hasMatch(params.phoneNumber.trim())) {
      return const Left(
        ValidationFailure(
          message:
              'Telefon raqami noto\'g\'ri formatda. Masalan: +998901234567',
        ),
      );
    }

    // Repository'ga murojaat
    return _repository.signInWithPhone(
      phoneNumber: params.phoneNumber.trim(),
    );
  }
}

/// Telefon bilan kirish parametrlari
class SignInWithPhoneParams extends Equatable {
  final String phoneNumber;

  const SignInWithPhoneParams({
    required this.phoneNumber,
  });

  @override
  List<Object> get props => [phoneNumber];
}
