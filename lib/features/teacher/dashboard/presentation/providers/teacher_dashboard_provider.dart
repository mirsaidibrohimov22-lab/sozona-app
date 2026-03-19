// lib/features/teacher/dashboard/presentation/providers/teacher_dashboard_provider.dart
// So'zona — Teacher Dashboard Riverpod providerlar
// FIXED: Firestore'dan haqiqiy sinflar va statistika olinadi

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/core/providers/firebase_providers.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';
import 'package:my_first_app/features/teacher/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:my_first_app/features/teacher/dashboard/data/repositories/dashboard_repository_impl.dart';

/// Sinf qisqacha ma'lumoti
class ClassSummary {
  final String id;
  final String name;
  final int studentCount;
  final String lastActivity;

  const ClassSummary({
    required this.id,
    required this.name,
    required this.studentCount,
    required this.lastActivity,
  });
}

/// Yaqinda bo'lgan hodisa
class RecentActivity {
  final String studentName;
  final String action;
  final String detail;
  final DateTime timestamp;

  const RecentActivity({
    required this.studentName,
    required this.action,
    required this.detail,
    required this.timestamp,
  });
}

/// Teacher Dashboard holati
class TeacherDashboardState {
  final UserEntity? user;
  final List<ClassSummary> classes;
  final List<RecentActivity> recentActivities;
  final int totalStudents;
  final int totalContent;
  final int publishedContent;
  final bool isLoading;
  final String? error;

  const TeacherDashboardState({
    this.user,
    this.classes = const [],
    this.recentActivities = const [],
    this.totalStudents = 0,
    this.totalContent = 0,
    this.publishedContent = 0,
    this.isLoading = false,
    this.error,
  });

  TeacherDashboardState copyWith({
    UserEntity? user,
    List<ClassSummary>? classes,
    List<RecentActivity>? recentActivities,
    int? totalStudents,
    int? totalContent,
    int? publishedContent,
    bool? isLoading,
    String? error,
  }) {
    return TeacherDashboardState(
      user: user ?? this.user,
      classes: classes ?? this.classes,
      recentActivities: recentActivities ?? this.recentActivities,
      totalStudents: totalStudents ?? this.totalStudents,
      totalContent: totalContent ?? this.totalContent,
      publishedContent: publishedContent ?? this.publishedContent,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Teacher Dashboard Notifier
class TeacherDashboardNotifier extends StateNotifier<TeacherDashboardState> {
  final Ref _ref;

  TeacherDashboardNotifier(this._ref) : super(const TeacherDashboardState());

  /// Dashboard ma'lumotlarini yuklash — Firestore'dan haqiqiy ma'lumot
  Future<void> loadDashboard(UserEntity? user) async {
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null, user: user);

    try {
      final repo = _ref.read(_dashboardRepositoryProvider);
      final result = await repo.getDashboardStats(user.id);

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
          );
        },
        (stats) {
          // DashboardStats dan ClassSummary ro'yxatiga o'girish
          // Firestore'dan kelgan sinflarni ko'rsatish uchun
          // teacherClassesProvider dan sinflarni ham o'qiymiz
          _loadClassesAndUpdate(user, stats);
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ma\'lumotlarni yuklashda xatolik: $e',
      );
    }
  }

  /// Sinflarni Firestore'dan yuklash va state yangilash
  Future<void> _loadClassesAndUpdate(UserEntity user, dynamic stats) async {
    try {
      final firestore = _ref.read(firestoreProvider);

      // Firestore'dan teacher sinflarini olish
      final snapshot = await firestore
          .collection('classes')
          .where('teacherId', isEqualTo: user.id)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final classSummaries = snapshot.docs.map((doc) {
        final data = doc.data();
        return ClassSummary(
          id: doc.id,
          name: data['name'] as String? ?? '',
          studentCount: (data['memberCount'] as num?)?.toInt() ?? 0,
          lastActivity: '',
        );
      }).toList();

      final totalStudents = classSummaries.fold<int>(
        0,
        (sum, c) => sum + c.studentCount,
      );

      // Kontent soni: har bir sinfning contentCount ni qo'shish
      final totalContent = snapshot.docs.fold<int>(0, (sum, doc) {
        final data = doc.data();
        return sum + ((data['contentCount'] as num?)?.toInt() ?? 0);
      });

      state = state.copyWith(
        isLoading: false,
        classes: classSummaries,
        totalStudents: totalStudents,
        totalContent: stats?.contentPublished ?? totalContent,
        publishedContent: stats?.contentPublished ?? totalContent,
        recentActivities: const [],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sinflarni yuklashda xatolik: $e',
      );
    }
  }

  /// Yangilash
  Future<void> refresh() async {
    await loadDashboard(state.user);
  }
}

/// Dashboard repository provider (internal)
final _dashboardRepositoryProvider = Provider((ref) {
  final firestore = ref.watch(firestoreProvider);
  final dataSource = DashboardRemoteDataSourceImpl(firestore);
  return DashboardRepositoryImpl(dataSource);
});

/// Teacher Dashboard provider
final teacherDashboardProvider =
    StateNotifierProvider<TeacherDashboardNotifier, TeacherDashboardState>(
        (ref) {
  return TeacherDashboardNotifier(ref);
});
