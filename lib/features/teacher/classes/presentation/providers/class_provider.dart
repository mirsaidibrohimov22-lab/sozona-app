// lib/features/teacher/classes/presentation/providers/class_provider.dart
// So'zona — Sinf Riverpod provider'lari
//
// ✅ FIX: GetClasses usecase import olib tashlandi.
//    TeacherClassesNotifier endi repository ni to'g'ridan-to'g'ri chaqiradi.
//    (get_classes.dart lokal faylda xato bo'lib qolgan edi — cascade error)
//    classMembersProvider kabi yondashuv ishlatiladi.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/teacher/classes/data/repositories/class_repository_impl.dart';
import 'package:my_first_app/features/teacher/classes/domain/entities/school_class.dart';
import 'package:my_first_app/features/teacher/classes/domain/entities/student_summary.dart';
import 'package:my_first_app/features/teacher/classes/domain/usecases/add_student_to_class.dart';
import 'package:my_first_app/features/teacher/classes/domain/usecases/create_class.dart';
import 'package:my_first_app/features/teacher/classes/domain/usecases/remove_student_from_class.dart';

// ═══════════════════════════════════
// USE CASE PROVIDERS
// ═══════════════════════════════════

final createClassUseCaseProvider = Provider<CreateClass>((ref) {
  return CreateClass(ref.watch(classRepositoryProvider));
});

final joinClassUseCaseProvider = Provider<JoinClassByCode>((ref) {
  return JoinClassByCode(ref.watch(classRepositoryProvider));
});

final removeStudentUseCaseProvider = Provider<RemoveStudentFromClass>((ref) {
  return RemoveStudentFromClass(ref.watch(classRepositoryProvider));
});

// ═══════════════════════════════════
// TEACHER SINFLARI
// ═══════════════════════════════════

/// Teacher'ning barcha sinflari
final teacherClassesProvider =
    AsyncNotifierProvider<TeacherClassesNotifier, List<SchoolClass>>(
  TeacherClassesNotifier.new,
);

class TeacherClassesNotifier extends AsyncNotifier<List<SchoolClass>> {
  @override
  Future<List<SchoolClass>> build() async {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    if (user == null) return [];

    // ✅ FIX: repository to'g'ridan-to'g'ri — GetClasses usecase kerak emas
    final repository = ref.watch(classRepositoryProvider);
    final result = await repository.getClasses(teacherId: user.id);

    return result.fold(
      (failure) => throw Exception(
          _mapClassFailureMessage(failure.message, failure.code)),
      (classes) => classes,
    );
  }

  /// Sinf yaratish
  Future<void> createClass({
    required String name,
    String? description,
    required String language,
    required String level,
  }) async {
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;
    if (user == null) return;

    state = const AsyncLoading();

    final useCase = ref.read(createClassUseCaseProvider);
    final result = await useCase(
      CreateClassParams(
        name: name,
        description: description,
        teacherId: user.id,
        teacherName: user.displayName,
        language: language,
        level: level,
      ),
    );

    result.fold(
      (failure) {
        final msg = _mapClassFailureMessage(failure.message, failure.code);
        state = AsyncError(msg, StackTrace.current);
        throw Exception(msg);
      },
      (newClass) {
        final current = state.valueOrNull ?? [];
        state = AsyncData([newClass, ...current]);
      },
    );
  }

  /// Ro'yxatni yangilash
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

// ─── Error mapping ────────────────────────────────────────────
String _mapClassFailureMessage(String message, String? code) {
  if (code == 'permission-denied' ||
      message.toLowerCase().contains('permission') ||
      message.toLowerCase().contains('insufficient')) {
    return 'Sinflarni yuklashda ruxsat muammosi yuz berdi. '
        "Hisobingiz teacher sifatida to'g'ri sozlanganini tekshiring.";
  }
  if (code == 'not-found' || message.toLowerCase().contains('topilmadi')) {
    return 'Sinflar topilmadi.';
  }
  if (code == 'unavailable' || message.toLowerCase().contains('network')) {
    return "Internet ulanishini tekshiring va qayta urinib ko'ring.";
  }
  if (code == 'unauthenticated' || message.toLowerCase().contains('auth')) {
    return "Tizimga qayta kiring va urinib ko'ring.";
  }
  return 'Sinflarni yuklashda xatolik: $message';
}

// ═══════════════════════════════════
// SINF A'ZOLARI
// ═══════════════════════════════════

/// Bitta sinf a'zolari (classId bo'yicha)
final classMembersProvider =
    FutureProvider.family<List<StudentSummary>, String>(
  (ref, classId) async {
    final repository = ref.watch(classRepositoryProvider);
    final result = await repository.getClassMembers(classId: classId);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (members) => members,
    );
  },
);

/// O'quvchini sinfdan chiqarish
Future<void> removeStudentAndRefresh({
  required WidgetRef ref,
  required String classId,
  required String studentId,
}) async {
  final authState = ref.read(authNotifierProvider);
  final user = authState.user;
  if (user == null) throw Exception('Tizimga kirish kerak');

  final useCase = ref.read(removeStudentUseCaseProvider);
  final result = await useCase(
    RemoveStudentParams(
      classId: classId,
      studentId: studentId,
      teacherId: user.id,
    ),
  );

  result.fold(
    (failure) => throw Exception(failure.message),
    (_) => ref.invalidate(classMembersProvider(classId)),
  );
}

// ═══════════════════════════════════
// STUDENT SINFLARI (Join Class)
// ═══════════════════════════════════

/// Student qo'shilgan sinflar
final studentClassesProvider =
    AsyncNotifierProvider<StudentClassesNotifier, List<SchoolClass>>(
  StudentClassesNotifier.new,
);

class StudentClassesNotifier extends AsyncNotifier<List<SchoolClass>> {
  @override
  Future<List<SchoolClass>> build() async {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    if (user == null) return [];

    final repository = ref.watch(classRepositoryProvider);
    final result = await repository.getStudentClasses(studentId: user.id);

    return result.fold(
      (failure) => throw Exception(failure.message),
      (classes) => classes,
    );
  }

  /// Join code orqali sinfga qo'shilish
  Future<String?> joinClass(String joinCode) async {
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;
    if (user == null) return 'Tizimga kirish kerak';

    final useCase = ref.read(joinClassUseCaseProvider);
    final result = await useCase(
      JoinClassParams(
        joinCode: joinCode,
        studentId: user.id,
        studentName: user.displayName,
        studentLevel: user.level.name.toUpperCase(),
      ),
    );

    return result.fold(
      (failure) => failure.message,
      (newClass) {
        final current = state.valueOrNull ?? [];
        if (!current.any((c) => c.id == newClass.id)) {
          state = AsyncData([...current, newClass]);
        }
        return null;
      },
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

// ═══════════════════════════════════
// TANLANGAN SINF
// ═══════════════════════════════════

/// Hozir ko'rilayotgan sinf ID si
final selectedClassIdProvider = StateProvider<String?>((ref) => null);

/// Tanlangan sinf ma'lumotlari
final selectedClassProvider = Provider<SchoolClass?>((ref) {
  final classId = ref.watch(selectedClassIdProvider);
  if (classId == null) return null;

  final classes = ref.watch(teacherClassesProvider).valueOrNull ?? [];
  return classes.where((c) => c.id == classId).firstOrNull;
});
