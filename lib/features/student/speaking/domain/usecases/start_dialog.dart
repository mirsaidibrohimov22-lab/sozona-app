// lib/features/student/speaking/domain/usecases/start_dialog.dart
// So'zona — Speaking dialog boshlash use case

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/speaking/domain/entities/speaking_exercise.dart';
import 'package:my_first_app/features/student/speaking/domain/repositories/speaking_repository.dart';

/// Speaking dialog boshlash — AI bilan yangi dialog generatsiya qilish
class StartDialog extends UseCase<SpeakingExercise, StartDialogParams> {
  final SpeakingRepository repository;

  StartDialog(this.repository);

  @override
  Future<Either<Failure, SpeakingExercise>> call(StartDialogParams params) {
    return repository.generateDialog(
      topic: params.topic,
      language: params.language,
      level: params.level,
    );
  }
}

class StartDialogParams extends Equatable {
  final String topic;
  final String language;
  final String level;

  const StartDialogParams({
    required this.topic,
    required this.language,
    required this.level,
  });

  @override
  List<Object?> get props => [topic, language, level];
}
