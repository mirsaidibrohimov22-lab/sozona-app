// QO'YISH: lib/features/teacher/classes/domain/usecases/create_class.dart
// So'zona — Sinf yaratish use case

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/teacher/classes/domain/entities/school_class.dart';
import 'package:my_first_app/features/teacher/classes/domain/repositories/class_repository.dart';

/// Yangi sinf yaratish
///
/// Bolaga tushuntirish:
/// O'qituvchi sinf yaratadi — nom, til, daraja kiritadi.
/// Avtomatik 6 belgili join code yaratiladi.
class CreateClass extends UseCase<SchoolClass, CreateClassParams> {
  final ClassRepository _repository;

  CreateClass(this._repository);

  @override
  Future<Either<Failure, SchoolClass>> call(CreateClassParams params) async {
    // Validatsiya
    if (params.name.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Sinf nomi bo\'sh bo\'lmasin',
          field: 'name',
        ),
      );
    }

    if (params.name.trim().length < 3) {
      return const Left(
        ValidationFailure(
          message: 'Sinf nomi kamida 3 ta belgi bo\'lsin',
          field: 'name',
        ),
      );
    }

    return _repository.createClass(
      name: params.name.trim(),
      description: params.description?.trim(),
      teacherId: params.teacherId,
      teacherName: params.teacherName,
      language: params.language,
      level: params.level,
    );
  }
}

/// CreateClass parametrlari
class CreateClassParams extends Equatable {
  /// Sinf nomi
  final String name;

  /// Sinf tavsifi (ixtiyoriy)
  final String? description;

  /// O'qituvchi identifikatori
  final String teacherId;

  /// O'qituvchi ismi
  final String teacherName;

  /// O'rganish tili: "en" | "de"
  final String language;

  /// CEFR darajasi: "A1" | "A2" | "B1" | "B2" | "C1"
  final String level;

  const CreateClassParams({
    required this.name,
    this.description,
    required this.teacherId,
    required this.teacherName,
    required this.language,
    required this.level,
  });

  @override
  List<Object?> get props => [name, teacherId, language, level];
}
