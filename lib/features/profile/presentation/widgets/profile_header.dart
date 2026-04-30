// lib/features/profile/presentation/widgets/profile_header.dart
// So'zona — Profil bosh qismi (avatar + ism + daraja)
// ✅ FIX 1: CachedNetworkImageProvider → CachedNetworkImage widget
//    Sabab: backgroundImage xato bo'lsa jim o'tiradi — rasm ko'rinmaydi
//    CachedNetworkImage widget: loading + error + fallback to'liq ishlaydi
// ✅ FIX 2: Rasm o'chirish tugmasi qo'shildi
//    Foydalanuvchi rasmni bosib tursa — "O'chirish" va "Almashtirish" menu chiqadi

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/widgets/level_badge.dart';
import 'package:my_first_app/features/profile/domain/entities/profile.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onAvatarDelete; // ✅ FIX 2: O'chirish callback
  final bool isUploadingAvatar;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.onAvatarTap,
    this.onAvatarDelete,
    this.isUploadingAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // ── Avatar ──────────────────────────────────────────────
          GestureDetector(
            onTap: onAvatarTap,
            // ✅ FIX 2: Bosib tursa — menyu chiqaradi
            onLongPress: profile.avatarUrl != null
                ? () => _showAvatarOptions(context)
                : null,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Avatar rasm ──────────────────────────────────
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 2),
                  ),
                  child: ClipOval(
                    child: profile.avatarUrl != null &&
                            profile.avatarUrl!.isNotEmpty
                        // ✅ FIX 1: CachedNetworkImage widget
                        // backgroundImage o'rniga — error va loading to'liq ishlaydi
                        ? CachedNetworkImage(
                            imageUrl: profile.avatarUrl!,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.primary,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white54,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            // ✅ URL xato bo'lsa yoki yuklanmasa — harflar bilan fallback
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.primaryDark,
                              alignment: Alignment.center,
                              child: Text(
                                profile.initials,
                                style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        // Rasm yo'q — harflar
                        : Container(
                            color: AppColors.primaryDark,
                            alignment: Alignment.center,
                            child: Text(
                              profile.initials,
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),

                // ── Yuklanayotgan holat ───────────────────────────
                if (isUploadingAvatar)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                  )

                // ── Kamera + O'chirish tugmalari ─────────────────
                else if (onAvatarTap != null) ...[
                  // Kamera — pastki o'ng
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 15,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  // ✅ FIX 2: O'chirish — pastki chap (faqat rasm bo'lsa)
                  if (profile.avatarUrl != null &&
                      profile.avatarUrl!.isNotEmpty &&
                      onAvatarDelete != null)
                    Positioned(
                      left: -2,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () => _showDeleteConfirm(context),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Ism ──────────────────────────────────────────────────
          Text(
            profile.fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

          // ── Statistika ───────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (profile.level != null) LevelBadge(level: profile.level!),
              const SizedBox(width: 8),
              _StatChip(icon: '🔥', value: '${profile.currentStreak}'),
              const SizedBox(width: 8),
              _StatChip(icon: '⚡', value: '${profile.totalXp} XP'),
            ],
          ),

          // ✅ Bosib turish haqida maslahat
          if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              "Rasmni bosib turing — o'chirish yoki almashtirish",
              style: TextStyle(
                color: Colors.white.withOpacity(0.50),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── O'chirish tasdiqlash dialogi ─────────────────────────────────
  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Rasmni o'chirish"),
        content: const Text("Profil rasmingizni o'chirmoqchimisiz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onAvatarDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );
  }

  // ── Bosib turganda menyu ──────────────────────────────────────────
  void _showAvatarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Profil rasm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (onAvatarTap != null)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEEF2FF),
                  child: Icon(Icons.camera_alt, color: Color(0xFF6366F1)),
                ),
                title: const Text('Almashtirish'),
                onTap: () {
                  Navigator.pop(ctx);
                  onAvatarTap?.call();
                },
              ),
            if (onAvatarDelete != null)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFEEEE),
                  child: Icon(Icons.delete_outline, color: Colors.red),
                ),
                title: const Text(
                  "O'chirish",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirm(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon, value;
  const _StatChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$icon $value',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
}
