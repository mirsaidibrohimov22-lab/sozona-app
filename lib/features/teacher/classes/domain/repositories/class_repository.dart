// QO'YISH: lib/features/teacher/classes/domain/repositories/class_repository.dart
// So'zona — Sinf repository interfeysi (Domain Layer)
// Data layer bilan shartnoma — nima qila olishini belgilaydi

import 'package:dartz/dartz.dart';

import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/teacher/classes/domain/entities/school_class.dart';
import 'package:my_first_app/features/teacher/classes/domain/entities/student_summary.dart';

/// Sinf repository interfeysi
///
/// Bolaga tushuntirish:
/// Bu — menyudagi taomlar ro'yxati. Nima buyurtma berish
/// mumkinligini ko'rsatadi, lekin oshxonada qanday tayyorlanishi
/// seni qiziqtirmaydi. Repository ham shunday.
abstract class ClassRepository {
  // ═══════════════════════════════════
  // SINFLAR (CLASSES)
  // ═══════════════════════════════════

  /// O'qituvchining barcha sinflarini olish
  Future<Either<Failure, List<SchoolClass>>> getClasses({
    required String teacherId,
  });

  /// Sinf yaratish
  /// [name] — sinf nomi
  /// [language] — "en" | "de"
  /// [level] — "A1" | "A2" | "B1" | "B2" | "C1"
  Future<Either<Failure, SchoolClass>> createClass({
    required String name,
    String? description,
    required String teacherId,
    required String teacherName,
    required String language,
    required String level,
  });

  /// Sinf ma'lumotlarini yangilash
  Future<Either<Failure, SchoolClass>> updateClass({
    required String classId,
    String? name,
    String? description,
    bool? isActive,
  });

  /// Sinfni o'chirish (arxivlash)
  Future<Either<Failure, void>> deleteClass({
    required String classId,
    required String teacherId,
  });

  /// Bitta sinf ma'lumotini olish
  Future<Either<Failure, SchoolClass>> getClassById({
    required String classId,
  });

  // ═══════════════════════════════════
  // A'ZOLAR (MEMBERS)
  // ═══════════════════════════════════

  /// Sinf a'zolari ro'yxatini olish
  Future<Either<Failure, List<StudentSummary>>> getClassMembers({
    required String classId,
  });

  /// Join code orqali sinfga qo'shilish (student uchun)
  /// [joinCode] — 6 belgili kod
  /// [studentId] — o'quvchi ID
  Future<Either<Failure, SchoolClass>> joinClassByCode({
    required String joinCode,
    required String studentId,
    required String studentName,
    required String studentLevel,
  });

  /// O'quvchini sinfga qo'shish (teacher tomonidan)
  Future<Either<Failure, void>> addStudentToClass({
    required String classId,
    required String studentId,
    required String teacherId,
  });

  /// O'quvchini sinfdan chiqarish (teacher tomonidan)
  Future<Either<Failure, void>> removeStudentFromClass({
    required String classId,
    required String studentId,
    required String teacherId,
  });

  /// O'quvchi o'zi sinfdan chiqishi
  Future<Either<Failure, void>> leaveClass({
    required String classId,
    required String studentId,
  });

  // ═══════════════════════════════════
  // STUDENT SINFLARI
  // ═══════════════════════════════════

  /// Student qo'shilgan sinflar ro'yxatini olish
  Future<Either<Failure, List<SchoolClass>>> getStudentClasses({
    required String studentId,
  });
}
