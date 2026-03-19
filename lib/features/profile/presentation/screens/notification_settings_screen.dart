// QO'YISH: lib/features/profile/presentation/screens/notification_settings_screen.dart
// So'zona — Bildirishnoma sozlamalari ekrani

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/widgets/app_snackbar.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/profile/domain/entities/profile.dart';
import 'package:my_first_app/features/profile/presentation/providers/profile_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);
    final user = ref.watch(authNotifierProvider).user;
    final profile = state.profile;
    final notif = profile?.notifications ?? const UserNotificationSettings();

    Future<void> update(UserNotificationSettings updated) async {
      if (user == null) return;
      await ref
          .read(profileProvider.notifier)
          .updateNotifications(user.id, updated);
      if (context.mounted) {
        final err = ref.read(profileProvider).error;
        if (err != null) {
          AppSnackbar.error(context, err);
        } else {
          AppSnackbar.success(context, 'Saqlandi');
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirishnomalar')),
      body: ListView(
        children: [
          _NotifTile(
            icon: Icons.timer_outlined,
            title: 'Mikro-sessiya eslatmasi',
            subtitle: 'Har 1 soatda — 10 daqiqa mashq vaqti',
            value: notif.microSession,
            onChanged: (v) => update(notif.copyWith(microSession: v)),
          ),
          _NotifTile(
            icon: Icons.local_fire_department_outlined,
            title: 'Streak eslatmasi',
            subtitle: 'Streak uzilmasliği uchun kunlik eslatma',
            value: notif.streak,
            onChanged: (v) => update(notif.copyWith(streak: v)),
          ),
          _NotifTile(
            icon: Icons.school_outlined,
            title: 'Yangi kontent',
            subtitle: "O'qituvchi yangi topshiriq qo'shganda",
            value: notif.teacherContent,
            onChanged: (v) => update(notif.copyWith(teacherContent: v)),
          ),
          if (state.isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SwitchListTile(
        secondary: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        value: value,
        activeThumbColor: AppColors.primary,
        onChanged: onChanged,
      );
}
