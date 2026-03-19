// lib/core/router/app_router.dart
// So'zona — GoRouter konfiguratsiya
// ✅ 1-KUN FIX: StudentShell 2 tab: Bosh sahifa + Profil
// ✅ 1-KUN FIX: Barcha inline hardcoded pathlar RoutePaths ga ko'chirildi
// ✅ 1-KUN FIX: flashcardReview, quizPlay, quizResult, privacy route qo'shildi
// ✅ 1-KUN FIX: duplicate /student/settings route olib tashlandi
// ✅ REFACTOR FIX: TeacherShell ga Profile tab qo'shildi (4-tab)
//   ESKI: Teacher 3 tab — Dashboard, Sinflar, Kontent (Profile yo'q edi!)
//   YANGI: Teacher 4 tab — Dashboard, Sinflar, Kontent, Profil
//   SABAB: Teacher ham profilni ko'rishi, sozlamalarni o'zgartirishi,
//          chiqishi kerak. /profile shared route ishlatiladi.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ── Auth ekranlar ──
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:my_first_app/features/auth/presentation/screens/login_screen.dart';
import 'package:my_first_app/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:my_first_app/features/auth/presentation/screens/phone_verify_screen.dart';
import 'package:my_first_app/features/auth/presentation/screens/register_screen.dart';
import 'package:my_first_app/features/auth/presentation/screens/setup_profile_screen.dart';
import 'package:my_first_app/features/auth/presentation/screens/splash_screen.dart';

// ── Student ekranlar ──
import 'package:my_first_app/features/student/home/presentation/screens/student_home_screen.dart';
import 'package:my_first_app/features/student/flashcards/presentation/screens/flashcard_list_screen.dart';
import 'package:my_first_app/features/student/flashcards/presentation/screens/cards_list_screen.dart';
import 'package:my_first_app/features/student/flashcards/presentation/screens/flashcard_practice_screen.dart';
import 'package:my_first_app/features/student/flashcards/presentation/screens/flashcard_search_screen.dart';
import 'package:my_first_app/features/student/flashcards/presentation/screens/review_screen.dart';
import 'package:my_first_app/features/student/quiz/presentation/screens/quiz_list_screen.dart';
import 'package:my_first_app/features/student/quiz/presentation/screens/quiz_detail_screen.dart';
import 'package:my_first_app/features/student/quiz/presentation/screens/quiz_play_screen.dart';
import 'package:my_first_app/features/student/quiz/presentation/screens/quiz_result_screen.dart';
import 'package:my_first_app/features/student/listening/presentation/screens/listening_list_screen.dart';
import 'package:my_first_app/features/student/listening/presentation/screens/listening_play_screen.dart';
import 'package:my_first_app/features/student/speaking/presentation/screens/speaking_list_screen.dart';
import 'package:my_first_app/features/student/speaking/presentation/screens/speaking_screen.dart';
import 'package:my_first_app/features/student/ai_chat/presentation/screens/ai_chat_screen.dart';
import 'package:my_first_app/features/student/artikel/presentation/screens/artikel_list_screen.dart';
import 'package:my_first_app/features/student/progress/presentation/screens/progress_screen.dart';
import 'package:my_first_app/features/student/join_class/presentation/screens/join_class_screen.dart';
import 'package:my_first_app/features/student/classes/presentation/screens/student_class_list_screen.dart';
import 'package:my_first_app/features/student/classes/presentation/screens/student_class_detail_screen.dart';
import 'package:my_first_app/features/learning_loop/presentation/screens/micro_session_screen.dart';

// ── Teacher ekranlar ──
import 'package:my_first_app/features/teacher/dashboard/presentation/screens/teacher_dashboard_screen.dart';
import 'package:my_first_app/features/teacher/classes/presentation/screens/class_list_screen.dart';
import 'package:my_first_app/features/teacher/classes/presentation/screens/class_detail_screen.dart';
import 'package:my_first_app/features/teacher/classes/presentation/screens/class_create_screen.dart';
import 'package:my_first_app/features/teacher/classes/presentation/screens/student_detail_screen.dart';
import 'package:my_first_app/features/teacher/content_generator/presentation/screens/content_generator_screen.dart';
import 'package:my_first_app/features/teacher/content_generator/presentation/screens/content_preview_screen.dart';
import 'package:my_first_app/features/teacher/publishing/presentation/screens/publishing_screen.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/entities/generated_content.dart';
import 'package:my_first_app/features/teacher/analytics/presentation/screens/teacher_analytics_screen.dart';

// ── Profil va Sozlamalar ──
import 'package:my_first_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:my_first_app/features/profile/presentation/screens/settings_screen.dart';
import 'package:my_first_app/features/profile/presentation/screens/notification_settings_screen.dart';
import 'package:my_first_app/features/profile/presentation/screens/privacy_screen.dart';

// ── Core ──
import 'package:my_first_app/core/router/guards/auth_guard.dart';
import 'package:my_first_app/core/router/route_names.dart';

/// Auth holatini GoRouter ga uzatish uchun listenable
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(this._ref) {
    try {
      _ref.listen<AuthState>(authNotifierProvider, (_, __) {
        notifyListeners();
      });
    } catch (e) {
      debugPrint('⚠️ AuthNotifier listen xatosi: $e');
    }
  }

  final Ref _ref;

  AuthState get authState {
    try {
      return _ref.read(authNotifierProvider);
    } catch (e) {
      debugPrint("⚠️ authState o'qish xatosi: $e");
      return const AuthState(status: AuthStatus.initial);
    }
  }
}

/// GoRouter provider — faqat bir marta yaratiladi
final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);

  final router = GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      try {
        return AuthGuard.redirect(
          authState: authNotifier.authState,
          currentPath: state.matchedLocation,
        );
      } catch (e) {
        debugPrint('⚠️ Router redirect xatosi: $e');
        return null;
      }
    },
    routes: [
      // ═══════════════════════════════════════
      // AUTH YO'LLARI
      // ═══════════════════════════════════════
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.phoneVerify,
        name: RouteNames.phoneVerify,
        builder: (context, state) {
          final extra = Map<String, String>.from(
            state.extra as Map? ?? {},
          );
          return PhoneVerifyScreen(
            verificationId: extra['verificationId'] ?? '',
            phoneNumber: extra['phoneNumber'] ?? '',
          );
        },
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.setupProfile,
        name: RouteNames.setupProfile,
        builder: (context, state) => const SetupProfileScreen(),
      ),

      // ═══════════════════════════════════════
      // STUDENT SHELL — 2 ta tab: Bosh sahifa + Profil
      // ✅ 1-KUN FIX: 6 tab → 2 tab
      // Qolgan modullar (Flashcard, Quiz, Listening, Speaking,
      // AI Chat, Progress) sub-route sifatida shell tashqarisida
      // ═══════════════════════════════════════
      ShellRoute(
        builder: (context, state, child) => _StudentShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.studentHome,
            name: RouteNames.studentHome,
            builder: (context, state) => const StudentHomeScreen(),
          ),
          // ✅ Profil alohida tab sifatida
          GoRoute(
            path: RoutePaths.profile,
            name: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ═══════════════════════════════════════
      // STUDENT SUB-ROUTES (shell tashqarisida)
      // Bu ekranlar full-screen ochiladi, bottom nav ko'rinmaydi
      // ═══════════════════════════════════════

      // ── Flashcards ──
      GoRoute(
        path: RoutePaths.flashcards,
        name: RouteNames.flashcards,
        builder: (context, state) => const FoldersScreen(),
      ),
      GoRoute(
        path: RoutePaths.flashcardDetail,
        name: RouteNames.flashcardDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CardsListScreen(folderId: id);
        },
      ),
      GoRoute(
        path: RoutePaths.flashcardFolder,
        name: RouteNames.flashcardFolder,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CardsListScreen(folderId: id);
        },
      ),
      GoRoute(
        path: RoutePaths.flashcardSearch,
        name: RouteNames.flashcardSearch,
        builder: (context, state) => const FlashcardSearchScreen(),
      ),
      GoRoute(
        path: RoutePaths.flashcardPractice,
        name: RouteNames.flashcardPractice,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return FlashcardPracticeScreen(setId: id);
        },
      ),
      GoRoute(
        path: RoutePaths.flashcardReview,
        name: RouteNames.flashcardReview,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ReviewScreen(folderId: id);
        },
      ),

      // ── Quiz ──
      GoRoute(
        path: RoutePaths.quiz,
        name: RouteNames.quiz,
        builder: (context, state) => const QuizListScreen(),
      ),
      // ✅ FIX: quizPlay va quizResult AVVAL ro'yxatlanishi kerak!
      // SABAB: GoRouter routelarni TARTIB bilan tekshiradi.
      // Agar quizDetail (/student/quiz/:id) birinchi bo'lsa,
      // /student/quiz/play ham :id='play' sifatida match qilinadi
      // → Firestore'da 'play' id topilmaydi → "Quiz topilmadi" xatosi.
      // QOIDA: Literal path (play, result) har doim wildcard (:id) dan OLDIN!
      GoRoute(
        path: RoutePaths.quizPlay,
        name: RouteNames.quizPlay,
        builder: (context, state) => const QuizPlayScreen(),
      ),
      GoRoute(
        path: RoutePaths.quizResult,
        name: RouteNames.quizResult,
        builder: (context, state) => const QuizResultScreen(),
      ),
      GoRoute(
        path: RoutePaths.quizDetail,
        name: RouteNames.quizDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return QuizDetailScreen(quizId: id);
        },
      ),

      // ── Listening ──
      GoRoute(
        path: RoutePaths.listening,
        name: RouteNames.listening,
        builder: (context, state) => const ListeningListScreen(),
      ),
      GoRoute(
        path: RoutePaths.listeningDetail,
        name: RouteNames.listeningDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ListeningPlayScreen(exerciseId: id);
        },
      ),

      // ── Speaking ──
      GoRoute(
        path: RoutePaths.speaking,
        name: RouteNames.speaking,
        builder: (context, state) => const SpeakingListScreen(),
      ),
      GoRoute(
        path: RoutePaths.speakingSession,
        name: RouteNames.speakingSession,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return SpeakingScreen(exerciseId: id);
        },
      ),

      // ── AI Chat ──
      GoRoute(
        path: RoutePaths.aiChat,
        name: RouteNames.aiChat,
        builder: (context, state) => const AiChatScreen(),
      ),

      // ── Artikel ──
      GoRoute(
        path: RoutePaths.artikel,
        name: RouteNames.artikel,
        builder: (context, state) => const ArtikelListScreen(),
      ),

      // ── Progress ──
      GoRoute(
        path: RoutePaths.progress,
        name: RouteNames.progress,
        builder: (context, state) => const ProgressScreen(),
      ),

      // ── Micro Session ──
      GoRoute(
        path: RoutePaths.microSession,
        name: RouteNames.microSession,
        builder: (context, state) => const MicroSessionScreen(),
      ),

      // ── Join Class ──
      GoRoute(
        path: RoutePaths.joinClass,
        name: RouteNames.joinClass,
        builder: (context, state) => const JoinClassScreen(),
      ),

      // ── Student Sinflar ro'yxati ──
      GoRoute(
        path: RoutePaths.studentClasses,
        name: RouteNames.studentClasses,
        builder: (context, state) => const StudentClassListScreen(),
      ),

      // ── Student Sinf detail ──
      GoRoute(
        path: RoutePaths.studentClassDetail,
        name: RouteNames.studentClassDetail,
        builder: (context, state) {
          final classId = state.pathParameters['id'] ?? '';
          return StudentClassDetailScreen(classId: classId);
        },
      ),

      // ═══════════════════════════════════════
      // TEACHER SHELL — Bottom Navigation
      // ✅ REFACTOR FIX: 3 tab → 4 tab (Profile qo'shildi)
      // ESKI: Dashboard | Sinflar | Kontent
      // YANGI: Dashboard | Sinflar | Kontent | Profil
      // ═══════════════════════════════════════
      ShellRoute(
        builder: (context, state, child) => _TeacherShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.teacherDashboard,
            name: RouteNames.teacherDashboard,
            builder: (context, state) => const TeacherDashboardScreen(),
          ),
          GoRoute(
            path: RoutePaths.teacherClasses,
            name: RouteNames.teacherClasses,
            builder: (context, state) => const ClassListScreen(),
          ),
          GoRoute(
            path: RoutePaths.contentGenerator,
            name: RouteNames.contentGenerator,
            builder: (context, state) => const ContentGeneratorScreen(),
          ),
          // ✅ YANGI: Teacher profile tab — /profile shared route
          GoRoute(
            path: RoutePaths.teacherProfile,
            name: RouteNames.teacherProfile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ═══════════════════════════════════════
      // TEACHER SUB-ROUTES
      // ═══════════════════════════════════════
      GoRoute(
        path: RoutePaths.contentPreview,
        name: RouteNames.contentPreview,
        builder: (context, state) {
          final content = state.extra as GeneratedContent?;
          if (content == null) return const SizedBox.shrink();
          return ContentPreviewScreen(content: content);
        },
      ),
      GoRoute(
        path: RoutePaths.publishing,
        name: RouteNames.publishing,
        builder: (context, state) {
          final content = state.extra as GeneratedContent?;
          if (content == null) return const SizedBox.shrink();
          return PublishingScreen(content: content);
        },
      ),
      GoRoute(
        path: RoutePaths.classDetail,
        name: RouteNames.classDetail,
        builder: (context, state) {
          final classId = state.pathParameters['id'] ?? '';
          return ClassDetailScreen(classId: classId);
        },
      ),
      GoRoute(
        path: RoutePaths.studentDetail,
        name: RouteNames.studentDetail,
        builder: (context, state) {
          final classId = state.pathParameters['classId'] ?? '';
          final studentId = state.pathParameters['studentId'] ?? '';
          return StudentDetailScreen(classId: classId, studentId: studentId);
        },
      ),
      GoRoute(
        path: RoutePaths.classCreate,
        name: RouteNames.classCreate,
        builder: (context, state) => const ClassCreateScreen(),
      ),
      GoRoute(
        path: RoutePaths.teacherAnalytics,
        name: RouteNames.teacherAnalytics,
        builder: (context, state) {
          final classId = state.pathParameters['classId'] ?? '';
          if (classId.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Analitika')),
              body: const Center(
                child: Text('Sinf tanlanmagan. Orqaga qaytib sinfni tanlang.'),
              ),
            );
          }
          return TeacherAnalyticsScreen(classId: classId);
        },
      ),

      // ═══════════════════════════════════════
      // SHARED YO'LLAR
      // ─── /profile teacher shell ichida bo'lgani uchun
      //     /settings, /notifications, /privacy shared sifatida qoladi
      // ═══════════════════════════════════════
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.notifications,
        name: RouteNames.notifications,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.privacy,
        name: RouteNames.privacy,
        builder: (context, state) => const PrivacyScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Sahifa topilmadi',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.splash),
              child: const Text('Bosh sahifaga qaytish'),
            ),
          ],
        ),
      ),
    ),
  );

  ref.onDispose(() {
    authNotifier.dispose();
    router.dispose();
  });

  return router;
});

// ═══════════════════════════════════════
// STUDENT SHELL — 2 TA TAB
// ✅ 1-KUN FIX: 6 tab → 2 tab (Bosh sahifa + Profil)
// Flashcard, Quiz, Listening, Speaking, AI Chat, Natijalar
// endi dashboard ichidagi quick actions orqali ochiladi
// ═══════════════════════════════════════
class _StudentShell extends StatelessWidget {
  final Widget child;
  const _StudentShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Bosh sahifa',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(RoutePaths.studentHome)) return 0;
    if (location == RoutePaths.profile) return 1;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RoutePaths.studentHome);
      case 1:
        context.go(RoutePaths.profile);
    }
  }
}

// ═══════════════════════════════════════
// TEACHER SHELL — 4 TA TAB
// ✅ REFACTOR FIX: 3 tab → 4 tab
// Dashboard | Sinflar | Kontent | Profil
// ═══════════════════════════════════════
class _TeacherShell extends StatelessWidget {
  final Widget child;
  const _TeacherShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.class_outlined),
            selectedIcon: Icon(Icons.class_),
            label: 'Sinflar',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Kontent',
          ),
          // ✅ YANGI: Profil tab
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(RoutePaths.teacherDashboard)) return 0;
    if (location.startsWith(RoutePaths.teacherClasses)) return 1;
    if (location.startsWith(RoutePaths.contentGenerator)) return 2;
    if (location == RoutePaths.teacherProfile) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RoutePaths.teacherDashboard);
      case 1:
        context.go(RoutePaths.teacherClasses);
      case 2:
        context.go(RoutePaths.contentGenerator);
      case 3:
        context.go(RoutePaths.teacherProfile);
    }
  }
}
