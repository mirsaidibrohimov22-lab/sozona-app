// lib/features/auth/presentation/providers/auth_provider.dart
// So'zona — Auth Riverpod providerlar
// Presentation layer: UI holatini boshqarish

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/providers/network_provider.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:my_first_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:my_first_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';
import 'package:my_first_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_first_app/features/auth/domain/usecases/get_current_user.dart';
import 'package:my_first_app/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:my_first_app/features/auth/domain/usecases/sign_in_with_phone.dart';
import 'package:my_first_app/features/auth/domain/usecases/sign_out.dart';
import 'package:my_first_app/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:my_first_app/features/auth/domain/usecases/verify_otp.dart';

// ─── Tashqi bog'liqliklar ───

/// Logger provider
final loggerProvider = Provider<Logger>((ref) {
  return Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
    ),
  );
});

/// SharedPreferences provider (async)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences main() da override qilinishi kerak',
  );
});

/// NetworkInfo provider

/// Auth Remote DataSource
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    firebaseAuth: firebase_auth.FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    logger: ref.watch(loggerProvider),
  );
});

/// Auth Local DataSource
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl(
    prefs: ref.watch(sharedPreferencesProvider),
    logger: ref.watch(loggerProvider),
  );
});

// ─── Repository provider ───

/// Auth Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
    logger: ref.watch(loggerProvider),
  );
});

// ─── UseCase providerlar ───

final signInWithEmailProvider = Provider<SignInWithEmail>((ref) {
  return SignInWithEmail(ref.watch(authRepositoryProvider));
});

final signInWithPhoneProvider = Provider<SignInWithPhone>((ref) {
  return SignInWithPhone(ref.watch(authRepositoryProvider));
});

final verifyOtpProvider = Provider<VerifyOtp>((ref) {
  return VerifyOtp(ref.watch(authRepositoryProvider));
});

final signUpWithEmailProvider = Provider<SignUpWithEmail>((ref) {
  return SignUpWithEmail(ref.watch(authRepositoryProvider));
});

final signOutProvider = Provider<SignOut>((ref) {
  return SignOut(ref.watch(authRepositoryProvider));
});

final getCurrentUserProvider = Provider<GetCurrentUser>((ref) {
  return GetCurrentUser(ref.watch(authRepositoryProvider));
});

// ─── Auth holati ───

/// Auth holati — barcha ekranlar bu providerni kuzatadi
enum AuthStatus {
  /// Tekshirilmoqda (splash screen)
  initial,

  /// Foydalanuvchi kirgan
  authenticated,

  /// Foydalanuvchi kirmagan
  unauthenticated,

  /// Profil hali sozlanmagan
  profileIncomplete,
}

/// Auth holat modeli
class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final Failure? failure;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.failure,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    Failure? failure,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      failure: failure,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Auth Notifier — auth holatini boshqaradi
class AuthNotifier extends StateNotifier<AuthState> {
  final SignInWithEmail _signInWithEmail;
  final SignInWithPhone _signInWithPhone;
  final VerifyOtp _verifyOtp;
  final SignUpWithEmail _signUpWithEmail;
  final SignOut _signOut;
  final GetCurrentUser _getCurrentUser;
  final AuthRepository _repository;
  final Logger _logger;

  AuthNotifier({
    required SignInWithEmail signInWithEmail,
    required SignInWithPhone signInWithPhone,
    required VerifyOtp verifyOtp,
    required SignUpWithEmail signUpWithEmail,
    required SignOut signOut,
    required GetCurrentUser getCurrentUser,
    required AuthRepository repository,
    required Logger logger,
  })  : _signInWithEmail = signInWithEmail,
        _signInWithPhone = signInWithPhone,
        _verifyOtp = verifyOtp,
        _signUpWithEmail = signUpWithEmail,
        _signOut = signOut,
        _getCurrentUser = getCurrentUser,
        _repository = repository,
        _logger = logger,
        super(const AuthState());

  /// Ilovani boshlashda auth holatini tekshirish
  Future<void> checkAuthStatus() async {
    _logger.d('Auth holati tekshirilmoqda...');

    final result = await _getCurrentUser(const NoParams());

    result.fold(
      (failure) {
        _logger.w('Auth tekshiruv xatolik: ${failure.message}');
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
        );
      },
      (user) {
        if (user == null) {
          _logger.d('Foydalanuvchi kirmagan');
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
          );
        } else if (!user.isProfileComplete) {
          _logger.d('Profil tugallanmagan: ${user.id}');
          state = state.copyWith(
            status: AuthStatus.profileIncomplete,
            user: user,
          );
        } else {
          _logger.d('Foydalanuvchi kirgan: ${user.id}');
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
          );
          // ✅ FIX: Cache-dan tez yuklab, fonda serverdan yangilaymiz
          // Sabab: cache'da eski isPremium=false bo'lishi mumkin
          // (promo kod yoki admin tomonidan premium faollashtirilgan bo'lsa)
          // Bu UI ni blokirovka qilmaydi — fon da ishlaydi
          // ignore: discarded_futures
          refreshUserFromServer();
        }
      },
    );
  }

  /// Email bilan kirish
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, failure: null);

    final result = await _signInWithEmail(
      SignInWithEmailParams(email: email, password: password),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          failure: failure,
        );
      },
      (user) async {
        state = state.copyWith(
          isLoading: false,
          status: user.isProfileComplete
              ? AuthStatus.authenticated
              : AuthStatus.profileIncomplete,
          user: user,
        );
      },
    );
  }

  /// Telefon bilan OTP yuborish
  Future<String?> signInWithPhone({required String phoneNumber}) async {
    state = state.copyWith(isLoading: true, failure: null);

    final result = await _signInWithPhone(
      SignInWithPhoneParams(phoneNumber: phoneNumber),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          failure: failure,
        );
        return null;
      },
      (verificationId) {
        state = state.copyWith(isLoading: false);
        // Avtomatik tasdiqlash bo'lgan bo'lsa — auth holatini yangilaymiz
        if (verificationId == 'auto_verified') {
          // ignore: discarded_futures
          checkAuthStatus();
          return null; // OTP ekraniga o'tmaymiz
        }
        return verificationId;
      },
    );
  }

  /// OTP tasdiqlash
  Future<void> verifyOtp({
    required String verificationId,
    required String otpCode,
  }) async {
    state = state.copyWith(isLoading: true, failure: null);

    final result = await _verifyOtp(
      VerifyOtpParams(
        verificationId: verificationId,
        otpCode: otpCode,
      ),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          failure: failure,
        );
      },
      (user) {
        state = state.copyWith(
          isLoading: false,
          status: user.isProfileComplete
              ? AuthStatus.authenticated
              : AuthStatus.profileIncomplete,
          user: user,
        );
      },
    );
  }

  /// Yangi hisob yaratish
  Future<void> signUpWithEmail({
    required String displayName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, failure: null);

    final result = await _signUpWithEmail(
      SignUpWithEmailParams(
        displayName: displayName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      ),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          failure: failure,
        );
      },
      (user) async {
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.profileIncomplete,
          user: user,
        );
      },
    );
  }

  /// ✅ FIX: Server dan majburiy yangilash — premium, daraja o'zgargandan keyin
  /// redeemPromoCode, updateProfile dan keyin shu metodni chaqiring
  Future<void> refreshUserFromServer() async {
    _logger.d('Server dan foydalanuvchi yangilanmoqda...');
    final result = await _repository.getCurrentUser(forceServer: true);
    result.fold(
      (failure) {
        _logger.w('Refresh xatolik: ${failure.message}');
      },
      (user) {
        if (user != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
          );
          _logger.d('✅ Foydalanuvchi yangilandi: isPremium=${user.isPremium}');
        }
      },
    );
  }

  /// Profilni sozlash (setup profile)
  Future<void> updateProfile({required UserEntity updatedUser}) async {
    state = state.copyWith(isLoading: true, failure: null);

    final result = await _repository.updateProfile(user: updatedUser);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          failure: failure,
        );
      },
      (user) {
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.authenticated,
          user: user,
        );
      },
    );
  }

  /// Chiqish
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, failure: null);

    final result = await _signOut(const NoParams());

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          failure: failure,
        );
      },
      (_) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      },
    );
  }

  /// Parol tiklash
  Future<bool> resetPassword({required String email}) async {
    state = state.copyWith(isLoading: true, failure: null);

    final result = await _repository.resetPassword(email: email);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          failure: failure,
        );
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }

  /// Xatolikni tozalash
  void clearFailure() {
    state = state.copyWith(failure: null);
  }
}

/// Auth Notifier provider — UI bu providerni ishlatadi
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    signInWithEmail: ref.watch(signInWithEmailProvider),
    signInWithPhone: ref.watch(signInWithPhoneProvider),
    verifyOtp: ref.watch(verifyOtpProvider),
    signUpWithEmail: ref.watch(signUpWithEmailProvider),
    signOut: ref.watch(signOutProvider),
    getCurrentUser: ref.watch(getCurrentUserProvider),
    repository: ref.watch(authRepositoryProvider),
    logger: ref.watch(loggerProvider),
  );
});

/// Auth holatini stream sifatida kuzatish (GoRouter uchun)
final authStateStreamProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
