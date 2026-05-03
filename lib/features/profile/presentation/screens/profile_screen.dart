// QO'YISH: lib/features/profile/presentation/screens/profile_screen.dart
// So'zona — Profil ekrani
// ✅ 1-KUN FIX: /student/settings → RoutePaths.settings
// ✅ 1-KUN FIX: /login → RoutePaths.login
// ✅ FIX: isUzbek bepul premium o'chirildi, promokod qo'shildi

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/features/premium/presentation/providers/premium_provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final _promoCtrl = TextEditingController();
  final _picker = ImagePicker();
  String? _selectedLanguage;
  String? _selectedLevel;
  int? _selectedGoal;
  bool _isDirty = false;
  bool _isRedeemingPromo = false;
  // avatarVisibility dialog orqali olinadi

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;
    // Profil allaqachon yuklangan bo'lsa, faqat formni to'ldirish (Firestore ga qayta so'rov yubormaslik)
    final alreadyLoaded = ref.read(profileProvider).profile;
    if (alreadyLoaded != null) {
      _initForm(); // ✅ FIX: form qiymatlarini mavjud profildan yuklash
      return;
    }
    ref.read(profileProvider.notifier).loadProfile(user.id);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _promoCtrl.dispose();
    super.dispose();
  }

  void _initForm() {
    final profile = ref.read(profileProvider).profile;
    if (profile == null) return;
    // Ism faqat birinchi marta to'ldiriladi
    if (_nameCtrl.text.isEmpty) {
      _nameCtrl.text = profile.fullName;
    }
    // ✅ FIX: Daraja, til va maqsad har doim profildan o'qiladi (??= emas, to'g'ridan)
    _selectedLanguage ??= profile.preferredLanguage;
    _selectedLevel ??= profile.level;
    _selectedGoal ??= profile.dailyGoalMinutes;
  }

  // ✅ YANGI: Rasmni o'rganlash va yuklash
  Future<void> _pickAvatar() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    // Ko'rinish sozlamasini so'rash
    final visibility = await _showVisibilityDialog();
    if (visibility == null) return;

    // Galereya yoki kameradan tanlash
    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;

      await ref.read(profileProvider.notifier).uploadAvatar(
            userId: user.id,
            filePath: picked.path,
            visibility: visibility,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xato: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ✅ YANGI: Rasmni o'chirish
  Future<void> _deleteAvatar() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;
    try {
      await ref.read(profileProvider.notifier).deleteAvatar(userId: user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Rasm o'chirildi"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xato: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<AvatarVisibility?> _showVisibilityDialog() async {
    return showDialog<AvatarVisibility>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Rasm ko'rinishi"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _VisibilityTile(
              icon: Icons.public,
              label: "Hammaga ko'rinadi",
              subtitle: 'Barcha foydalanuvchilar',
              value: AvatarVisibility.everyone,
              onTap: () => Navigator.pop(ctx, AvatarVisibility.everyone),
            ),
            _VisibilityTile(
              icon: Icons.group,
              label: 'Faqat sinfga',
              subtitle: 'Faqat sinfdoshlaringiz',
              value: AvatarVisibility.classOnly,
              onTap: () => Navigator.pop(ctx, AvatarVisibility.classOnly),
            ),
            _VisibilityTile(
              icon: Icons.lock,
              label: 'Faqat men',
              subtitle: "Hech kim ko'rmaydi",
              value: AvatarVisibility.onlyMe,
              onTap: () => Navigator.pop(ctx, AvatarVisibility.onlyMe),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
        ],
      ),
    );
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Rasm tanlash',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEEF2FF),
                child: Icon(Icons.photo_library, color: Color(0xFF6366F1)),
              ),
              title: const Text('Galereya'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEEF2FF),
                child: Icon(Icons.camera_alt, color: Color(0xFF6366F1)),
              ),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _redeemPromoCode() async {
    final code = _promoCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isRedeemingPromo = true);
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      await functions.httpsCallable('redeemPromoCode').call({'code': code});
      if (!mounted) return;
      _promoCtrl.clear();
      AppSnackbar.success(context, '🎉 Premium bir oyga faollashdi!');
      // ✅ FIX: server dan majburiy yangilash — isPremium cache da eski qolmasin
      await ref.read(authNotifierProvider.notifier).refreshUserFromServer();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'not-found' => 'Promo kod topilmadi',
        'already-exists' => 'Bu promo kodni allaqachon ishlatgansiz',
        'resource-exhausted' => 'Promo kod ishlatilgan',
        'failed-precondition' => 'Promo kod muddati tugagan',
        _ => e.message ?? 'Xatolik yuz berdi',
      };
      AppSnackbar.error(context, msg);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Xatolik yuz berdi. Qayta urining.');
    } finally {
      if (mounted) setState(() => _isRedeemingPromo = false);
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
      // ✅ FIX: server dan majburiy yangilash
      await ref.read(authNotifierProvider.notifier).refreshUserFromServer();
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
          ProfileHeader(
            profile: profile,
            onAvatarTap: _pickAvatar,
            onAvatarDelete:
                _deleteAvatar, // ✅ YANGI: O'chirish tugmasi ishlaydi
            isUploadingAvatar: ref.watch(profileProvider).isUploadingAvatar,
          ),

          // ✅ YANGI: Badges bo'limi — faqat badge bo'lsa ko'rinadi
          if (profile.badges.isNotEmpty) _BadgesSection(badges: profile.badges),
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

                // Til — faqat o'quvchiga ko'rinadi
                // ✅ FIX: O'qituvchi til tanlamaydi — u til o'RGATADI, o'rganmaydi
                if (!isTeacher) ...[
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
                ],

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
                  const SizedBox(height: 12),

                  // ✅ YANGI: Referral tizimi — do'st tavsiya qilish
                  InkWell(
                    onTap: () => context.push(RoutePaths.referral),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF4F46E5).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.card_giftcard_outlined,
                              color: Colors.white, size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Do'st tavsiya qilish 🎁",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Taklif qiling — ikkalangiz 7 kun premium oling!',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ✅ YANGI: Promokod bo'limi — faqat o'quvchiga, premium yo'q bo'lsa
                if (!isTeacher && !ref.watch(hasPremiumProvider)) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Promo kod',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Promo kod orqali 1 oylik premium oling',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  // ✅ Telegram bot banner
                  _TelegramBotBanner(),
                  const SizedBox(height: 12),
                  // Promo kod input
                  TextField(
                    controller: _promoCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'PROMO KOD kiriting...',
                      hintStyle: TextStyle(
                          letterSpacing: 1,
                          fontSize: 13,
                          color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.confirmation_number_outlined,
                          color: Color(0xFF6366F1)),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF6366F1), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Faollashtirish tugmasi
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isRedeemingPromo ? null : _redeemPromoCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isRedeemingPromo
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Faollashtirish',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ✅ YANGI: Premium kartochkasi — faqat o'quvchiga
                if (!isTeacher) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  _PremiumBanner(),
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

// ═══════════════════════════════════════════════════════════════
// ✅ YANGI: Premium Banner — profil ekranida
// ═══════════════════════════════════════════════════════════════
class _PremiumBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPremium = ref.watch(hasPremiumProvider);

    if (hasPremium) {
      // Premium faol
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0A00), Color(0xFF2A1500)],
          ),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium,
                color: Color(0xFFFFD700), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Premium Faol ✓',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Barcha premium imkoniyatlar ochiq',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.60),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push(RoutePaths.premium),
              child: const Text(
                "Ko'rish",
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Premium yo'q
    return InkWell(
      onTap: () => context.push(RoutePaths.premium),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0A3E), Color(0xFF0A0A2A)],
          ),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
              ),
              child: const Icon(Icons.workspace_premium,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium olish',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "AI murabbiy, tabiiy ovoz va ko'proq",
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// Ko'rinish tanlash tile
// ═══════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
// Telegram Bot Banner — promo kod olish uchun
// ═══════════════════════════════════════════════════════════════
class _TelegramBotBanner extends StatelessWidget {
  const _TelegramBotBanner();
  static const _botUrl = 'https://t.me/sozona_payment_bot';

  Future<void> _openBot() async {
    final uri = Uri.parse(_botUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openBot,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0088CC), Color(0xFF29B6F6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0088CC).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('✈️', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Promo kod olish',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "@sozona_payment_bot orqali to'lov qiling",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final AvatarVisibility value;
  final VoidCallback onTap;

  const _VisibilityTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFEEF2FF),
        child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BADGES BO'LIMI — profil ekranida header dan keyin ko'rinadi
// ═══════════════════════════════════════════════════════════════

class _BadgesSection extends StatelessWidget {
  final List<String> badges;
  const _BadgesSection({required this.badges});

  // Badge ma'lumotlari — emoji, nom, rang, tavsif
  static const Map<String, Map<String, String>> _badgeData = {
    'weekly_champion': {
      'emoji': '🏆',
      'title': 'Weekly Champion',
      'desc': '7 kun ketma-ket',
      'color': 'gold',
    },
    'sozana_legend': {
      'emoji': '👑',
      'title': 'Sozana Legend',
      'desc': '100 kun streak!',
      'color': 'purple',
    },
    'lucky_star': {
      'emoji': '⭐',
      'title': 'Lucky Star',
      'desc': 'Kunlik sovg\'adan',
      'color': 'orange',
    },
  };

  static Color _badgeColor(String badge) {
    final c = _badgeData[badge]?['color'] ?? 'blue';
    switch (c) {
      case 'gold':
        return const Color(0xFFFFB300);
      case 'purple':
        return const Color(0xFF7C4DFF);
      case 'orange':
        return const Color(0xFFFF7043);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sarlavha
          Row(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Mening nishonlarim',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${badges.length} ta',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Badge grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: badges
                .map((b) => _BadgeCard(
                      badge: b,
                      data: _badgeData[b] ??
                          {
                            'emoji': '🏅',
                            'title': b,
                            'desc': 'Nishon',
                            'color': 'blue',
                          },
                      color: _badgeColor(b),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String badge;
  final Map<String, String> data;
  final Color color;

  const _BadgeCard({
    required this.badge,
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = data['emoji'] ?? '🏅';
    final title = data['title'] ?? badge;
    final desc = data['desc'] ?? '';

    return Container(
      width: (MediaQuery.of(context).size.width - 32 - 16 - 20) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Row(
        children: [
          // Emoji doira
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 10),
          // Matn
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
