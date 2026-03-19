// QO'YISH: lib/features/profile/presentation/providers/profile_provider.dart
// So'zona — Profile Riverpod provider

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:my_first_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:my_first_app/features/profile/domain/entities/profile.dart';
import 'package:my_first_app/features/profile/domain/usecases/get_profile.dart';
import 'package:my_first_app/features/profile/domain/usecases/request_account_delete.dart';
import 'package:my_first_app/features/profile/domain/usecases/request_data_export.dart';
import 'package:my_first_app/features/profile/domain/usecases/update_preferences.dart';
import 'package:my_first_app/features/profile/domain/usecases/update_profile.dart';

// ─── Repository provider ───
final profileRepositoryProvider = Provider<ProfileRepositoryImpl>((ref) {
  return ProfileRepositoryImpl(
    remote: ProfileRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
      storage: FirebaseStorage.instance,
    ),
  );
});

// ─── State ───
class ProfileState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;
  final UserProfile? profile;

  const ProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
    this.profile,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    UserProfile? profile,
  }) =>
      ProfileState(
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        error: error,
        successMessage: successMessage,
        profile: profile ?? this.profile,
      );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepositoryImpl _repo;

  ProfileNotifier(this._repo) : super(const ProfileState());

  Future<void> loadProfile(String userId) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    final result = await GetProfile(_repo).call(userId);
    if (!mounted) return;
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (p) => state = state.copyWith(isLoading: false, profile: p),
    );
  }

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? level,
    String? preferredLanguage,
    String? uiLanguage,
    int? dailyGoalMinutes,
  }) async {
    if (!mounted) return;
    state = state.copyWith(isSaving: true);
    final result = await UpdateProfile(_repo).call(
      UpdateProfileParams(
        userId: userId,
        fullName: fullName,
        level: level,
        preferredLanguage: preferredLanguage,
        uiLanguage: uiLanguage,
        dailyGoalMinutes: dailyGoalMinutes,
      ),
    );
    if (!mounted) return;
    result.fold(
      (f) => state = state.copyWith(isSaving: false, error: f.message),
      (p) => state = state.copyWith(
        isSaving: false,
        profile: p,
        successMessage: 'Profil saqlandi',
      ),
    );
  }

  Future<void> updatePreferences(
    String userId,
    UserPreferences preferences,
  ) async {
    if (!mounted) return;
    state = state.copyWith(isSaving: true);
    final result = await UpdatePreferences(_repo).call(
      UpdatePreferencesParams(userId: userId, preferences: preferences),
    );
    if (!mounted) return;
    result.fold(
      (f) => state = state.copyWith(isSaving: false, error: f.message),
      (p) => state = state.copyWith(
        isSaving: false,
        profile: p,
        successMessage: 'Sozlamalar saqlandi',
      ),
    );
  }

  Future<void> updateNotifications(
    String userId,
    UserNotificationSettings notif,
  ) async {
    if (!mounted) return;
    state = state.copyWith(isSaving: true);
    final result = await _repo.updateNotificationSettings(
      userId: userId,
      notifications: notif,
    );
    if (!mounted) return;
    result.fold(
      (f) => state = state.copyWith(isSaving: false, error: f.message),
      (p) => state = state.copyWith(
        isSaving: false,
        profile: p,
        successMessage: 'Saqlandi',
      ),
    );
  }

  Future<bool> requestDataExport(String userId) async {
    final result = await RequestDataExport(_repo).call(userId);
    return result.fold((_) => false, (_) => true);
  }

  Future<bool> requestAccountDelete(String userId) async {
    final result = await RequestAccountDelete(_repo).call(userId);
    return result.fold((_) => false, (_) => true);
  }

  void clearMessages() =>
      state = state.copyWith(error: null, successMessage: null);
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref.watch(profileRepositoryProvider));
});
