// lib/features/auth/data/repositories/auth_repository_impl.dart
// So'zona — Auth Repository implementatsiyasi
// Remote + Local datasource'larni birlashtiradi
// Exception → Failure o'girishni boshqaradi

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/network/network_info.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';
import 'package:my_first_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_first_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:my_first_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:my_first_app/features/auth/data/models/user_model.dart';

/// Auth repository implementatsiyasi
/// Clean Architecture: Data layer — Exception → Failure
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final Logger _logger;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
    required Logger logger,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo,
        _logger = logger;

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // Internet tekshiruvi
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final user = await _remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );

      // Muvaffaqiyatli kirish — cache'ga saqlash
      await _localDataSource.cacheUser(user);
      _logger.i('SignIn muvaffaqiyatli: ${user.id}');

      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      _logger.e('SignIn kutilmagan xatolik: $e');
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, String>> signInWithPhone({
    required String phoneNumber,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final verificationId = await _remoteDataSource.signInWithPhone(
        phoneNumber: phoneNumber,
      );
      return Right(verificationId);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      _logger.e('SignInWithPhone xatolik: $e');
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String verificationId,
    required String otpCode,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final user = await _remoteDataSource.verifyOtp(
        verificationId: verificationId,
        otpCode: otpCode,
      );

      // Cache'ga saqlash
      await _localDataSource.cacheUser(user);
      _logger.i('OTP tasdiqlandi: ${user.id}');

      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      _logger.e('VerifyOtp xatolik: $e');
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final user = await _remoteDataSource.signUpWithEmail(
        displayName: displayName,
        email: email,
        password: password,
      );

      // Cache'ga saqlash
      await _localDataSource.cacheUser(user);
      _logger.i('SignUp muvaffaqiyatli: ${user.id}');

      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      _logger.e('SignUp xatolik: $e');
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remoteDataSource.signOut();

      // Mahalliy cache'ni tozalash
      await _localDataSource.clearCache();
      _logger.i('Muvaffaqiyatli chiqish');

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      _logger.e('SignOut xatolik: $e');
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      // Avval remote'dan urinish
      if (await _networkInfo.isConnected) {
        final user = await _remoteDataSource.getCurrentUser();
        if (user != null) {
          // Cache'ni yangilash
          await _localDataSource.cacheUser(user);
        }
        return Right(user);
      }

      // Offline bo'lsa — cache'dan olish
      _logger.d('Offline rejim — cache\'dan foydalanuvchi olinmoqda');
      final cachedUser = await _localDataSource.getCachedUser();
      return Right(cachedUser);
    } on AuthException catch (e) {
      // Foydalanuvchi topilmadi — cache'dan urinish
      _logger.w('Remote user not found, trying cache: ${e.message}');
      final cachedUser = await _localDataSource.getCachedUser();
      if (cachedUser != null) {
        return Right(cachedUser);
      }
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      // Server xatolik — cache'dan urinish
      _logger.w('Server error, trying cache: ${e.message}');
      final cachedUser = await _localDataSource.getCachedUser();
      return Right(cachedUser);
    } catch (e) {
      _logger.e('GetCurrentUser xatolik: $e');
      // Oxirgi imkoniyat — cache
      final cachedUser = await _localDataSource.getCachedUser();
      return Right(cachedUser);
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await _remoteDataSource.resetPassword(email: email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      _logger.e('ResetPassword xatolik: $e');
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    required UserEntity user,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final userModel = UserModel.fromEntity(user);
      final updatedUser = await _remoteDataSource.updateProfile(
        user: userModel,
      );

      // Cache'ni yangilash
      await _localDataSource.cacheUser(updatedUser);
      _logger.i('Profil yangilandi: ${user.id}');

      return Right(updatedUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      _logger.e('UpdateProfile xatolik: $e');
      return const Left(UnknownFailure());
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _remoteDataSource.authStateChanges.map((userModel) {
      if (userModel != null) {
        // Cache'ga saqlash (stream ichida async ishlatish uchun)
        _localDataSource.cacheUser(userModel).catchError((e) {
          _logger.e('Auth stream cache xatoligi: $e');
        });
      }
      return userModel;
    });
  }

  @override
  Future<Either<Failure, bool>> isEmailVerified() async {
    try {
      final isVerified = await _remoteDataSource.isEmailVerified();
      return Right(isVerified);
    } catch (e) {
      _logger.e('isEmailVerified xatolik: $e');
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> resendEmailVerification() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await _remoteDataSource.resendEmailVerification();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, code: e.code));
    } catch (e) {
      _logger.e('Resend verification xatolik: $e');
      return const Left(UnknownFailure());
    }
  }
}
