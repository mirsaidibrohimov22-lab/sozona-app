// lib/features/auth/domain/usecases/sign_up_with_email.dart
// So'zona — Ro'yxatdan o'tish use case
// Yangi hisob yaratish — email + parol + ism

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';
import 'package:my_first_app/features/auth/domain/repositories/auth_repository.dart';

/// Email bilan ro'yxatdan o'tish use case
/// Validatsiya: ism, email format, parol kuchi
class SignUpWithEmail implements UseCase<UserEntity, SignUpWithEmailParams> {
  final AuthRepository _repository;

  const SignUpWithEmail(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpWithEmailParams params) async {
    // Ism validatsiya
    if (params.displayName.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Ism kiritilishi shart'),
      );
    }

    if (params.displayName.trim().length < 2) {
      return const Left(
        ValidationFailure(
          message: 'Ism kamida 2 ta belgidan iborat bo\'lishi kerak',
        ),
      );
    }

    if (params.displayName.trim().length > 50) {
      return const Left(
        ValidationFailure(message: 'Ism 50 ta belgidan oshmasligi kerak'),
      );
    }

    // Email validatsiya
    if (params.email.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Email kiritilishi shart'),
      );
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(params.email.trim())) {
      return const Left(
        ValidationFailure(message: 'Email formati noto\'g\'ri'),
      );
    }

    // Parol validatsiya
    if (params.password.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Parol kiritilishi shart'),
      );
    }

    if (params.password.length < 8) {
      return const Left(
        ValidationFailure(
          message: 'Parol kamida 8 belgidan iborat bo\'lishi kerak',
        ),
      );
    }

    // Parol kuchliligini tekshirish
    final hasUpperCase = params.password.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = params.password.contains(RegExp(r'[a-z]'));
    final hasDigit = params.password.contains(RegExp(r'[0-9]'));

    if (!hasUpperCase || !hasLowerCase || !hasDigit) {
      return const Left(
        ValidationFailure(
          message: 'Parolda katta harf, kichik harf va raqam bo\'lishi shart',
        ),
      );
    }

    // Parol tasdig'i tekshiruvi
    if (params.password != params.confirmPassword) {
      return const Left(
        ValidationFailure(message: 'Parollar mos kelmadi'),
      );
    }

    // Repository'ga murojaat
    return _repository.signUpWithEmail(
      displayName: params.displayName.trim(),
      email: params.email.trim(),
      password: params.password,
    );
  }
}

/// Ro'yxatdan o'tish parametrlari
class SignUpWithEmailParams extends Equatable {
  final String displayName;
  final String email;
  final String password;
  final String confirmPassword;

  const SignUpWithEmailParams({
    required this.displayName,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object> get props => [displayName, email, password, confirmPassword];
}
