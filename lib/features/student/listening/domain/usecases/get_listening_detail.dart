// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Get Listening Detail UseCase
// QO'YISH: lib/features/student/listening/domain/usecases/get_listening_detail.dart
// ═══════════════════════════════════════════════════════════════

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/listening/domain/entities/listening_exercise.dart';
import 'package:my_first_app/features/student/listening/domain/repositories/listening_repository.dart';

/// Get Listening Detail UseCase
class GetListeningDetail
    implements UseCase<ListeningExercise, GetListeningDetailParams> {
  final ListeningRepository repository;

  GetListeningDetail(this.repository);

  @override
  Future<Either<Failure, ListeningExercise>> call(
    GetListeningDetailParams params,
  ) async {
    return await repository.getListeningDetail(params.exerciseId);
  }
}

/// Get Listening Detail parametrlari
class GetListeningDetailParams extends Equatable {
  final String exerciseId;

  const GetListeningDetailParams({required this.exerciseId});

  @override
  List<Object> get props => [exerciseId];
}
