// QO'YISH: lib/features/teacher/classes/domain/usecases/remove_student_from_class.dart
// So'zona — O'quvchini sinfdan chiqarish use case

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/teacher/classes/domain/repositories/class_repository.dart';

/// O'quvchini sinfdan chiqarish (teacher tomonidan)
class RemoveStudentFromClass extends UseCase<void, RemoveStudentParams> {
  final ClassRepository _repository;

  RemoveStudentFromClass(this._repository);

  @override
  Future<Either<Failure, void>> call(RemoveStudentParams params) async {
    return _repository.removeStudentFromClass(
      classId: params.classId,
      studentId: params.studentId,
      teacherId: params.teacherId,
    );
  }
}

/// RemoveStudent parametrlari
class RemoveStudentParams extends Equatable {
  /// Sinf identifikatori
  final String classId;

  /// O'quvchi identifikatori
  final String studentId;

  /// O'qituvchi identifikatori (ruxsatni tekshirish uchun)
  final String teacherId;

  const RemoveStudentParams({
    required this.classId,
    required this.studentId,
    required this.teacherId,
  });

  @override
  List<Object> get props => [classId, studentId, teacherId];
}
