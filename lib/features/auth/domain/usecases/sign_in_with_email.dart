import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';
import 'package:my_first_app/features/auth/domain/repositories/auth_repository.dart';

class SignInWithEmail implements UseCase<UserEntity, SignInWithEmailParams> {
  final AuthRepository _repository;
  const SignInWithEmail(this._repository);
  @override
  Future<Either<Failure, UserEntity>> call(SignInWithEmailParams params) =>
      _repository.signInWithEmail(email: params.email.trim(), password: params.password);
}

class SignInWithEmailParams extends Equatable {
  final String email;
  final String password;
  const SignInWithEmailParams({required this.email, required this.password});
  @override
  List<Object> get props => [email, password];
}
