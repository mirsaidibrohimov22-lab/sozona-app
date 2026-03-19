// QO'YISH: lib/features/teacher/classes/data/repositories/class_repository_impl.dart
// So'zona — Sinf repository implementatsiyasi (Data Layer)
// ClassRepository interfeysini amalga oshiradi

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/network/network_info.dart';
import 'package:my_first_app/core/providers/network_provider.dart';
import 'package:my_first_app/features/teacher/classes/data/datasources/class_remote_datasource.dart';
import 'package:my_first_app/features/teacher/classes/domain/entities/school_class.dart';
import 'package:my_first_app/features/teacher/classes/domain/entities/student_summary.dart';
import 'package:my_first_app/features/teacher/classes/domain/repositories/class_repository.dart';

/// ClassRepository ning Firestore implementatsiyasi
class ClassRepositoryImpl implements ClassRepository {
  final ClassRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ClassRepositoryImpl({
    required ClassRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, List<SchoolClass>>> getClasses({
    required String teacherId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await _remoteDataSource.getClasses(teacherId: teacherId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, SchoolClass>> createClass({
    required String name,
    String? description,
    required String teacherId,
    required String teacherName,
    required String language,
    required String level,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await _remoteDataSource.createClass(
        name: name,
        description: description,
        teacherId: teacherId,
        teacherName: teacherName,
        language: language,
        level: level,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, SchoolClass>> updateClass({
    required String classId,
    String? name,
    String? description,
    bool? isActive,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await _remoteDataSource.updateClass(
        classId: classId,
        name: name,
        description: description,
        isActive: isActive,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, void>> deleteClass({
    required String classId,
    required String teacherId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      // Arxivlash (isActive = false)
      await _remoteDataSource.updateClass(
        classId: classId,
        isActive: false,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, SchoolClass>> getClassById({
    required String classId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await _remoteDataSource.getClassById(classId: classId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, List<StudentSummary>>> getClassMembers({
    required String classId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await _remoteDataSource.getClassMembers(classId: classId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, SchoolClass>> joinClassByCode({
    required String joinCode,
    required String studentId,
    required String studentName,
    required String studentLevel,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await _remoteDataSource.joinClassByCode(
        joinCode: joinCode,
        studentId: studentId,
        studentName: studentName,
        studentLevel: studentLevel,
      );
      return Right(result);
    } on ServerException catch (e) {
      // Maxsus xatoliklarni aniqroq ko'rsatish
      if (e.code == 'CLASS_NOT_FOUND') {
        return const Left(
          ServerFailure(message: 'Bunday kod bilan sinf topilmadi'),
        );
      }
      if (e.code == 'ALREADY_MEMBER') {
        return const Left(
          ServerFailure(message: 'Siz bu sinfga allaqachon a\'zo siz'),
        );
      }
      if (e.code == 'CLASS_FULL') {
        return const Left(ServerFailure(message: 'Sinf to\'liq'));
      }
      return Left(ServerFailure(message: e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, void>> addStudentToClass({
    required String classId,
    required String studentId,
    required String teacherId,
  }) async {
    // Bu teacher tomonidan qo'lda qo'shish (hozircha join code orqali)
    return const Left(
      ServerFailure(message: 'Join code orqali qo\'shiling'),
    );
  }

  @override
  Future<Either<Failure, void>> removeStudentFromClass({
    required String classId,
    required String studentId,
    required String teacherId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await _remoteDataSource.removeStudentFromClass(
        classId: classId,
        studentId: studentId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, void>> leaveClass({
    required String classId,
    required String studentId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await _remoteDataSource.removeStudentFromClass(
        classId: classId,
        studentId: studentId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, List<SchoolClass>>> getStudentClasses({
    required String studentId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result =
          await _remoteDataSource.getStudentClasses(studentId: studentId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    }
  }
}

/// Provider
final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return ClassRepositoryImpl(
    remoteDataSource: ref.watch(classRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});
