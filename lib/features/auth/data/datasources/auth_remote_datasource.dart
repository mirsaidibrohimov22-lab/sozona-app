// lib/features/auth/data/datasources/auth_remote_datasource.dart
// So'zona — Auth Remote DataSource
// Firebase Auth va Firestore bilan bevosita ishlaydi

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:logger/logger.dart';

import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/features/auth/data/models/user_model.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<String> signInWithPhone({required String phoneNumber});

  Future<UserModel> verifyOtp({
    required String verificationId,
    required String otpCode,
  });

  Future<UserModel> signUpWithEmail({
    required String displayName,
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<UserModel?> getCurrentUser({bool forceServer = false});

  Future<void> resetPassword({required String email});

  Future<UserModel> updateProfile({required UserModel user});

  Stream<UserModel?> get authStateChanges;

  Future<bool> isEmailVerified();

  Future<void> resendEmailVerification();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final Logger _logger;

  static const String _usersCollection = 'users';

  AuthRemoteDataSourceImpl({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required Logger logger,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _logger = logger;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(_usersCollection);

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _logger.d('Email bilan kirish: $email');

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw AuthException(
          message: 'Kirish muvaffaqiyatsiz. Qaytadan urinib ko‘ring',
          code: 'USER_NULL',
        );
      }

      final userModel = await _getUserFromFirestore(firebaseUser.uid);

      await _usersRef.doc(firebaseUser.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      _logger.i('Muvaffaqiyatli kirish: ${firebaseUser.uid}');
      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth xatolik: ${e.code}');
      throw AuthException(
        message: _mapFirebaseAuthError(e.code),
        code: e.code,
      );
    } on AuthException {
      rethrow;
    } on ServerException {
      // _getUserFromFirestore dan kelgan ServerException — xabarini saqlab rethrow
      rethrow;
    } catch (e) {
      _logger.e('Kutilmagan xatolik: $e');
      throw ServerException(
        message: "Kirish amalga oshmadi. Qayta urinib ko'ring.",
      );
    }
  }

  @override
  Future<String> signInWithPhone({required String phoneNumber}) async {
    try {
      _logger.d('Telefon bilan kirish: $phoneNumber');

      final completer = Completer<String>();

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) {
          _logger.d('Avtomatik tasdiqlash');
        },
        verificationFailed: (e) {
          _logger.e('Telefon tasdiqlash xatoligi: ${e.code}');
          if (!completer.isCompleted) {
            completer.completeError(
              AuthException(
                message: _mapFirebaseAuthError(e.code),
                code: e.code,
              ),
            );
          }
        },
        codeSent: (verId, resendToken) {
          _logger.d('OTP yuborildi, verificationId: $verId');
          if (!completer.isCompleted) {
            completer.complete(verId);
          }
        },
        codeAutoRetrievalTimeout: (verId) {
          if (!completer.isCompleted) {
            completer.complete(verId);
          }
        },
      );

      return await completer.future;
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      _logger.e('Telefon kirish xatoligi: $e');
      throw ServerException(
        message: "Telefon orqali kirish amalga oshmadi. Qayta urinib ko'ring.",
      );
    }
  }

  @override
  Future<UserModel> verifyOtp({
    required String verificationId,
    required String otpCode,
  }) async {
    try {
      _logger.d('OTP tasdiqlash');

      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      final result = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = result.user;

      if (firebaseUser == null) {
        throw AuthException(
          message: 'Tasdiqlash muvaffaqiyatsiz',
          code: 'USER_NULL',
        );
      }

      final userDoc = await _usersRef.doc(firebaseUser.uid).get();

      if (userDoc.exists) {
        await _usersRef.doc(firebaseUser.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        return UserModel.fromFirestore(userDoc);
      } else {
        final newUser = UserModel(
          id: firebaseUser.uid,
          displayName: firebaseUser.displayName ?? '',
          email: firebaseUser.email ?? '',
          phoneNumber: firebaseUser.phoneNumber,
          role: UserRole.student,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _usersRef.doc(firebaseUser.uid).set(newUser.toFirestore());
        _logger.i('Yangi foydalanuvchi yaratildi: ${firebaseUser.uid}');
        return newUser;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.e('OTP tasdiqlash xatoligi: ${e.code}');
      throw AuthException(
        message: _mapFirebaseAuthError(e.code),
        code: e.code,
      );
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      _logger.e('OTP xatolik: $e');
      throw ServerException(
        message: "Tasdiqlash amalga oshmadi. Qayta urinib ko'ring.",
      );
    }
  }

  @override
  Future<UserModel> signUpWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      _logger.d('Ro‘yxatdan o‘tish: $email');

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw AuthException(
          message: 'Hisob yaratishda xatolik',
          code: 'USER_NULL',
        );
      }

      await firebaseUser.updateDisplayName(displayName);
      await firebaseUser.sendEmailVerification();

      final now = DateTime.now();
      final newUser = UserModel(
        id: firebaseUser.uid,
        displayName: displayName,
        email: email,
        role: UserRole.student,
        createdAt: now,
        updatedAt: now,
        lastLoginAt: now,
      );

      await _usersRef.doc(firebaseUser.uid).set(newUser.toFirestore());

      _logger.i('Yangi hisob yaratildi: ${firebaseUser.uid}');
      return newUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.e('Ro‘yxatdan o‘tish xatoligi: ${e.code}');
      throw AuthException(
        message: _mapFirebaseAuthError(e.code),
        code: e.code,
      );
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      _logger.e('SignUp xatolik: $e');
      throw ServerException(
        message: "Ro'yxatdan o'tish amalga oshmadi. Qayta urinib ko'ring.",
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      _logger.d('Tizimdan chiqish');
      await _firebaseAuth.signOut();
      _logger.i('Muvaffaqiyatli chiqish');
    } catch (e) {
      _logger.e('Chiqish xatoligi: $e');
      throw ServerException(
        message: 'Chiqishda xatolik yuz berdi',
      );
    }
  }

  @override
  Future<UserModel?> getCurrentUser({bool forceServer = false}) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        _logger.d('Hozirgi foydalanuvchi: yo‘q');
        return null;
      }

      _logger.d('Hozirgi foydalanuvchi: ${firebaseUser.uid}');
      return _getUserFromFirestore(firebaseUser.uid, forceServer: forceServer);
    } on ServerException {
      rethrow;
    } catch (e) {
      _logger.e('GetCurrentUser xatolik: $e');
      throw ServerException(
        message:
            "Foydalanuvchi ma'lumotlarini olishda xatolik. Qayta urinib ko'ring.",
      );
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      _logger.d('Parol tiklash: $email');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _logger.i('Parol tiklash emaili yuborildi');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.e('Parol tiklash xatoligi: ${e.code}');
      throw AuthException(
        message: _mapFirebaseAuthError(e.code),
        code: e.code,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      _logger.e('ResetPassword xatolik: $e');
      throw ServerException(
        message: "Parol tiklash amalga oshmadi. Qayta urinib ko'ring.",
      );
    }
  }

  @override
  Future<UserModel> updateProfile({required UserModel user}) async {
    try {
      _logger.d('Profil yangilash: ${user.id}');
      await _usersRef.doc(user.id).update(user.toUpdateMap());

      final updatedDoc = await _usersRef.doc(user.id).get();
      _logger.i('Profil yangilandi: ${user.id}');
      return UserModel.fromFirestore(updatedDoc);
    } catch (e) {
      _logger.e('Profil yangilash xatoligi: $e');
      throw ServerException(
        message: 'Profilni yangilashda xatolik',
      );
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        return await _getUserFromFirestore(firebaseUser.uid);
      } catch (e) {
        _logger.e('Auth state stream xatolik: $e');
        return null;
      }
    });
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;
    await user.reload();
    return user.emailVerified;
  }

  @override
  Future<void> resendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException(
          message: 'Foydalanuvchi topilmadi',
          code: 'USER_NULL',
        );
      }

      await user.sendEmailVerification();
      _logger.i('Email tasdiqlash qayta yuborildi');
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(
        message: _mapFirebaseAuthError(e.code),
        code: e.code,
      );
    }
  }

  // ✅ FIX: Cache-first strategiya
  // 1. Avval local Firestore cache dan o'qiymiz (offline ham ishlaydi, timeout yo'q)
  // 2. Cache da bo'lmasa, serverdan 20s timeout bilan olamiz (eski 8s juda kam edi)
  // 3. Timeout bo'lsa, foydalanuvchiga tushunarli xabar ko'rsatiladi
  // ✅ FIX: forceServer=true — premium/daraja o'zgarganda cache emas server dan o'qish
  Future<UserModel> _getUserFromFirestore(String uid,
      {bool forceServer = false}) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc;

      if (forceServer) {
        // ✅ Premium yoki profil o'zgargandan keyin — serverdan majburiy o'qish
        doc = await _usersRef
            .doc(uid)
            .get(const GetOptions(source: Source.server))
            .timeout(
              const Duration(seconds: 20),
              onTimeout: () => throw TimeoutException(
                "Internet sekin yoki Firebase bilan aloqa yo'q. "
                "Iltimos, internetni tekshirib, qayta urinib ko'ring.",
              ),
            );
        _logger.d('✅ Server dan olindi (forceServer): $uid');
      } else {
        try {
          // Birinchi — cache dan tez o'qish
          doc = await _usersRef
              .doc(uid)
              .get(const GetOptions(source: Source.cache));
          _logger.d('✅ Cache dan olindi: $uid');
        } catch (_) {
          // Cache da yo'q — serverdan yuklaymiz
          _logger.d("Cache yo'q, serverdan yuklanmoqda: $uid");
          doc = await _usersRef
              .doc(uid)
              .get(const GetOptions(source: Source.server))
              .timeout(
                const Duration(seconds: 20),
                onTimeout: () => throw TimeoutException(
                  "Internet sekin yoki Firebase bilan aloqa yo'q. "
                  "Iltimos, internetni tekshirib, qayta urinib ko'ring.",
                ),
              );
        }
      }

      if (!doc.exists) {
        throw AuthException(
          message: "Foydalanuvchi ma'lumotlari topilmadi",
          code: 'USER_NOT_FOUND',
        );
      }
      return UserModel.fromFirestore(doc);
    } on TimeoutException catch (e) {
      _logger.e('Firestore timeout: $e');
      throw ServerException(
        message: e.message ??
            'Internet sekin yoki Firebase bilan aloqa yo\'q. '
                'Iltimos, internetni tekshirib, qayta urinib ko\'ring.',
      );
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      _logger.e('Firestore xatolik: $e');
      throw ServerException(
        message: "Ma'lumot olishda xatolik. Qayta urinib ko'ring.",
      );
    }
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu email bilan hisob topilmadi';
      case 'wrong-password':
        return 'Parol noto‘g‘ri';
      case 'invalid-credential':
        return 'Email yoki parol noto‘g‘ri';
      case 'email-already-in-use':
        return 'Bu email allaqachon ro‘yxatdan o‘tgan';
      case 'weak-password':
        return 'Parol juda oddiy';
      case 'invalid-email':
        return 'Email formati noto‘g‘ri';
      case 'user-disabled':
        return 'Bu hisob bloklangan';
      case 'too-many-requests':
        return 'Juda ko‘p urinish. Biroz kuting';
      case 'operation-not-allowed':
        return 'Bu kirish usuli yoqilmagan';
      case 'invalid-verification-code':
        return 'Tasdiqlash kodi noto‘g‘ri';
      case 'invalid-verification-id':
        return 'Tasdiqlash muddati tugagan. Qaytadan urinib ko‘ring';
      case 'session-expired':
        return 'Sessiya muddati tugadi. Qaytadan kiring';
      default:
        return 'Xatolik yuz berdi. Qaytadan urinib ko‘ring';
    }
  }
}

class UnsupportedAuthRemoteDataSource implements AuthRemoteDataSource {
  final Logger _logger;
  final String message;

  UnsupportedAuthRemoteDataSource({
    required Logger logger,
    this.message =
        'Auth xizmati bu platformada hali sozlanmagan. Android ilovada sinab ko‘ring yoki Web App qo‘shib flutterfire configure ni qayta ishga tushiring.',
  }) : _logger = logger;

  Never _throwUnsupported() {
    _logger.w(message);
    throw AuthException(
      message: message,
      code: 'AUTH_PLATFORM_NOT_CONFIGURED',
    );
  }

  @override
  Stream<UserModel?> get authStateChanges => Stream<UserModel?>.value(null);

  @override
  Future<UserModel?> getCurrentUser({bool forceServer = false}) async => null;

  @override
  Future<bool> isEmailVerified() async => false;

  @override
  Future<void> resendEmailVerification() async => _throwUnsupported();

  @override
  Future<void> resetPassword({required String email}) async =>
      _throwUnsupported();

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      _throwUnsupported();

  @override
  Future<String> signInWithPhone({required String phoneNumber}) async =>
      _throwUnsupported();

  @override
  Future<void> signOut() async {}

  @override
  Future<UserModel> signUpWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async =>
      _throwUnsupported();

  @override
  Future<UserModel> updateProfile({required UserModel user}) async =>
      _throwUnsupported();

  @override
  Future<UserModel> verifyOtp({
    required String verificationId,
    required String otpCode,
  }) async =>
      _throwUnsupported();
}
