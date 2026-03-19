// lib/features/auth/domain/usecases/sign_in_with_email.dart
// So'zona — Email bilan kirish use case
// Clean Architecture: Har bir biznes logika alohida UseCase

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';
import 'package:my_first_app/features/auth/domain/repositories/auth_repository.dart';

/// Email bilan kirish use case
/// Validatsiya + repository chaqiruvi
class SignInWithEmail implements UseCase<UserEntity, SignInWithEmailParams> {
  final AuthRepository _repository;

  const SignInWithEmail(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignInWithEmailParams params) async {
    // Email validatsiya
    if (params.email.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Email kiritilishi shart'),
      );
    }

    // Email formatini tekshirish
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

    // Repository'ga murojaat
    return _repository.signInWithEmail(
      email: params.email.trim(),
      password: params.password,
    );
  }
}

/// Email bilan kirish parametrlari
class SignInWithEmailParams extends Equatable {
  final String email;
  final String password;

  const SignInWithEmailParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}
