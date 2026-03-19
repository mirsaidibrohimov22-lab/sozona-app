// QO'YISH: lib/features/profile/presentation/screens/profile_screen.dart
// So'zona — Profil ekrani
// ✅ 1-KUN FIX: /student/settings → RoutePaths.settings
// ✅ 1-KUN FIX: /login → RoutePaths.login

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/core/widgets/app_button.dart';
import 'package:my_first_app/core/widgets/app_error_widget.dart';
import 'package:my_first_app/core/widgets/app_loading_widget.dart';
import 'package:my_first_app/core/widgets/app_snackbar.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:my_first_app/features/profile/presentation/widgets/goal_setter.dart';
import 'package:my_first_app/features/profile/presentation/widgets/language_picker.dart';
import 'package:my_first_app/features/profile/presentation/widgets/level_picker.dart';
import 'package:my_first_app/features/profile/presentation/widgets/profile_header.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  String? _selectedLanguage;
  String? _selectedLevel;
  int? _selectedGoal;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;
    ref.read(profileProvider.notifier).loadProfile(user.id);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _initForm() {
    final profile = ref.read(profileProvider).profile;
    if (profile == null) return;
    if (_nameCtrl.text.isEmpty) {
      _nameCtrl.text = profile.fullName;
      _selectedLanguage ??= profile.preferredLanguage;
      _selectedLevel ??= profile.level;
      _selectedGoal ??= profile.dailyGoalMinutes;
    }
  }

  Future<void> _save() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;
    await ref.read(profileProvider.notifier).updateProfile(
          userId: user.id,
          fullName: _nameCtrl.text.trim(),
          level: _selectedLevel,
          preferredLanguage: _selectedLanguage,
          dailyGoalMinutes: _selectedGoal,
        );
    if (!mounted) return;
    final error = ref.read(profileProvider).error;
    if (error != null) {
      AppSnackbar.error(context, error);
    } else {
      AppSnackbar.success(context, 'Profil saqlandi!');
      setState(() => _isDirty = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

    ref.listen(profileProvider, (_, next) {
      if (next.profile != null) _initForm();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            // ✅ 1-KUN FIX: /student/settings → RoutePaths.settings
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
      body: state.isLoading
          ? const AppLoadingWidget()
          : state.error != null && state.profile == null
              ? AppErrorWidget(message: state.error!, onRetry: _load)
              : _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, ProfileState state) {
    final profile = state.profile;
    if (profile == null) return const SizedBox.shrink();

    final isTeacher = ref.read(authNotifierProvider).user?.isTeacher ?? false;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileHeader(profile: profile),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ism
                const Text(
                  'Ism',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  onChanged: (_) => setState(() => _isDirty = true),
                  decoration: const InputDecoration(hintText: 'Ismingiz'),
                ),
                const SizedBox(height: 20),

                // Til
                const Text(
                  "O'rganayotgan til",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                LanguagePicker(
                  selected: _selectedLanguage ?? 'en',
                  onChanged: (v) => setState(() {
                    _selectedLanguage = v;
                    _isDirty = true;
                  }),
                ),
                const SizedBox(height: 20),

                // Daraja — faqat o'quvchiga ko'rinadi
                if (!isTeacher) ...[
                  const Text(
                    'Daraja',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  LevelPicker(
                    selected: _selectedLevel ?? 'A1',
                    onChanged: (v) => setState(() {
                      _selectedLevel = v;
                      _isDirty = true;
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Kunlik maqsad — faqat o'quvchiga ko'rinadi
                  const Text(
                    'Kunlik maqsad',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  GoalSetter(
                    selectedMinutes: _selectedGoal ?? 20,
                    onChanged: (v) => setState(() {
                      _selectedGoal = v;
                      _isDirty = true;
                    }),
                  ),
                  const SizedBox(height: 32),
                ],

                if (isTeacher) const SizedBox(height: 12),

                if (_isDirty)
                  AppButton(
                    label: 'Saqlash',
                    isLoading: state.isSaving,
                    onPressed: _save,
                  ),
                const SizedBox(height: 16),

                // ── Mening sinfim — faqat o'quvchiga ko'rinadi ──
                if (!isTeacher) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Sinf',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => context.push(RoutePaths.joinClass),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.group_add_outlined,
                              color: Color(0xFF6366F1)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sinfga qo\'shilish',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'O\'qituvchi bergan 6 harfli kodni kiriting',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Chiqish
                AppButton(
                  label: 'Chiqish',
                  type: AppButtonType.outlined,
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    // ✅ 1-KUN FIX: /login → RoutePaths.login
                    if (context.mounted) context.go(RoutePaths.login);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
