// QO'YISH: lib/features/learning_loop/domain/usecases/get_next_session.dart
// So'zona — Keyingi mikro-sessiyani olish

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/micro_session.dart';
import 'package:my_first_app/features/learning_loop/domain/repositories/learning_loop_repository.dart';

class GetNextSessionParams extends Equatable {
  final String userId;
  const GetNextSessionParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Keyingi mikro-sessiyani olish yoki yaratish
class GetNextSession implements UseCase<MicroSession, GetNextSessionParams> {
  final LearningLoopRepository _repository;

  GetNextSession(this._repository);

  @override
  Future<Either<Failure, MicroSession>> call(
    GetNextSessionParams params,
  ) async {
    return _repository.getOrCreateNextSession(params.userId);
  }
}
