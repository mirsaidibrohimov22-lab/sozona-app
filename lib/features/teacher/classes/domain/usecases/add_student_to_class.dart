// QO'YISH: lib/features/teacher/classes/domain/usecases/add_student_to_class.dart
// So'zona — O'quvchini sinfga qo'shish use case
// Bu ikki holatda ishlatiladi:
// 1. Student o'zi join code bilan qo'shilganda
// 2. Teacher o'quvchini qo'shganda

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/teacher/classes/domain/entities/school_class.dart';
import 'package:my_first_app/features/teacher/classes/domain/repositories/class_repository.dart';

/// Join code orqali sinfga qo'shilish (student)
///
/// Bolaga tushuntirish:
/// O'qituvchi bergan 6 ta harfli kodni kiritasiz — sinfga qo'shilasiz.
/// Xuddi zal eshigidagi parol kabi.
class JoinClassByCode extends UseCase<SchoolClass, JoinClassParams> {
  final ClassRepository _repository;

  JoinClassByCode(this._repository);

  @override
  Future<Either<Failure, SchoolClass>> call(JoinClassParams params) async {
    // Validatsiya — 6 belgili kod
    final code = params.joinCode.trim().toUpperCase();

    if (code.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Qo\'shilish kodi bo\'sh bo\'lmasin',
          field: 'joinCode',
        ),
      );
    }

    if (code.length != 6) {
      return const Left(
        ValidationFailure(
          message: 'Qo\'shilish kodi 6 ta belgi bo\'lishi kerak',
          field: 'joinCode',
        ),
      );
    }

    return _repository.joinClassByCode(
      joinCode: code,
      studentId: params.studentId,
      studentName: params.studentName,
      studentLevel: params.studentLevel,
    );
  }
}

/// JoinClass parametrlari
class JoinClassParams extends Equatable {
  /// 6 belgili join code
  final String joinCode;

  /// O'quvchi identifikatori
  final String studentId;

  /// O'quvchi ismi
  final String studentName;

  /// O'quvchi darajasi
  final String studentLevel;

  const JoinClassParams({
    required this.joinCode,
    required this.studentId,
    required this.studentName,
    required this.studentLevel,
  });

  @override
  List<Object> get props => [joinCode, studentId];
}
