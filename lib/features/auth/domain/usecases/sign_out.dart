// lib/features/auth/domain/usecases/sign_out.dart
// So'zona — Tizimdan chiqish use case
// Oddiy use case — parametrsiz

import 'package:dartz/dartz.dart';

import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/auth/domain/repositories/auth_repository.dart';

/// Tizimdan chiqish use case
/// Firebase Auth + local cache tozalash
class SignOut implements UseCase<void, NoParams> {
  final AuthRepository _repository;

  const SignOut(this._repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return _repository.signOut();
  }
}
