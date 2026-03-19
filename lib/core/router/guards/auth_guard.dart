// lib/core/router/guards/auth_guard.dart
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/core/router/route_names.dart';

class AuthGuard {
  static String? redirect({
    required AuthState authState,
    required String currentPath,
  }) {
    final status = authState.status;

    // ✅ Splash o'zi yo'naltiradi — redirect qilma
    if (currentPath == RoutePaths.splash) return null;

    // Hali tekshirilmoqda
    if (status == AuthStatus.initial) return null;

    // Profil tugallanmagan
    if (status == AuthStatus.profileIncomplete) {
      if (currentPath == RoutePaths.setupProfile) return null;
      return RoutePaths.setupProfile;
    }

    // ✅ splash bu yerda YO'Q
    final publicPaths = [
      RoutePaths.onboarding,
      RoutePaths.login,
      RoutePaths.register,
      RoutePaths.phoneVerify,
      RoutePaths.forgotPassword,
    ];

    final isOnPublicPage = publicPaths.contains(currentPath);
    final isAuthenticated = status == AuthStatus.authenticated;

    // Kirmagan — himoyalangan sahifaga kirmoqchi
    if (!isAuthenticated && !isOnPublicPage) {
      return RoutePaths.login;
    }

    // Kirgan — public sahifada → bosh sahifaga
    if (isAuthenticated && isOnPublicPage) {
      return _getHomeForRole(authState.user);
    }

    // Rol tekshiruvi
    if (isAuthenticated && authState.user != null) {
      final isStudentPath = currentPath.startsWith('/student');
      final isTeacherPath = currentPath.startsWith('/teacher');

      if (authState.user!.isStudent && isTeacherPath) {
        return RoutePaths.studentHome;
      }
      if (authState.user!.isTeacher && isStudentPath) {
        return RoutePaths.teacherDashboard;
      }
    }

    return null;
  }

  static String _getHomeForRole(UserEntity? user) {
    if (user == null) return RoutePaths.login;
    return user.isTeacher
        ? RoutePaths.teacherDashboard
        : RoutePaths.studentHome;
  }

  static String getHomeRoute(UserEntity? user) {
    return _getHomeForRole(user);
  }
}
