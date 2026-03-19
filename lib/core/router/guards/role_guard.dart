// QO'YISH: lib/core/router/guards/role_guard.dart
// So'zona — Role asosida yo'naltirish (student/teacher)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';

String? roleGuard(Ref ref, GoRouterState state) {
  final authState = ref.read(authNotifierProvider);
  final user = authState.user;

  if (user == null) return RouteNames.login;

  final path = state.uri.path;

  // Student student yo'liga kirmoqchi — OK
  if (path.startsWith('/student') && user.isStudent) return null;
  // Teacher teacher yo'liga kirmoqchi — OK
  if (path.startsWith('/teacher') && user.isTeacher) return null;

  // Student teacher yo'liga kirishga urindi
  if (path.startsWith('/teacher') && user.isStudent) {
    return RouteNames.studentHome;
  }
  // Teacher student yo'liga kirishga urindi
  if (path.startsWith('/student') && user.isTeacher) {
    return RouteNames.teacherDashboard;
  }

  return null;
}
