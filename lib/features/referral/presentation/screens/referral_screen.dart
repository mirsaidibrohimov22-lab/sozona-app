// lib/features/referral/presentation/screens/referral_screen.dart
// So'zona — Referral (do'st tavsiya qilish) ekrani
// Tarkib:
//   1. Mukofotlar banneri  — qanday bonus olinishini tushuntiradi
//   2. QR kartochkasi      — skanerlash orqali do'st kodni oson kiritmaydi
//   3. Ulashish tugmasi    — share_plus orqali tizim sharidan foydalanadi
//   4. Kod kiritish bo'lim — birovning kodini qo'llash uchun

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:my_first_app/core/widgets/app_loading_widget.dart';
import 'package:my_first_app/core/widgets/app_snackbar.dart';
import 'package:my_first_app/features/referral/presentation/providers/referral_provider.dart';
import 'package:my_first_app/features/referral/presentation/widgets/qr_card_widget.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ekran ochilganda ma'lumotlarni yuklash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(referralProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Ulashish — Play Store linki bilan
  // ─────────────────────────────────────────────
  Future<void> _share(String code, String deepLink) async {
    // TODO: com.example.my_first_app → Play Store ga chiqilganda haqiqiy package ID
    const playStoreLink =
        'https://play.google.com/store/apps/details?id=com.example.my_first_app';

    final text = "So'zona — AI orqali ingliz/nemis tilini o'rganaman! 🎓\n\n"
        "Sen ham qo'shilsang — ikkalamiz 7 kun ichida faol bo'lsak, "
        '3 kun bepul premium olamiz!\n\n'
        '📲 Yuklab ol: $playStoreLink\n\n'
        '🔑 Mening tavsiya kodum: $code\n'
        "(Ilovani o'rnatgandan so'ng 'Profil → Do'st tavsiya' bo'limiga kir)";

    await Share.share(text, subject: "So'zona ilovasiga taklif");
  }

  // ─────────────────────────────────────────────
  // Kodni buferga nusxalash
  // ─────────────────────────────────────────────
  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    AppSnackbar.success(context, '✅ Kod nusxalandi: $code');
  }

  // ─────────────────────────────────────────────
  // Boshqaning kodini qo'llash
  // ─────────────────────────────────────────────
  Future<void> _redeem() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      AppSnackbar.error(context, 'Referral kodni kiriting.');
      return;
    }
    await ref.read(referralProvider.notifier).redeem(code);
    if (mounted) _codeCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(referralProvider);

    // Xabarlarni tinglash — SnackBar orqali ko'rsatish
    ref.listen<ReferralState>(referralProvider, (_, next) {
      if (!mounted) return;
      if (next.successMessage != null) {
        AppSnackbar.success(context, next.successMessage!);
        ref.read(referralProvider.notifier).clearMessages();
      }
      if (next.error != null) {
        AppSnackbar.error(context, next.error!);
        ref.read(referralProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Do'st tavsiya qilish",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF1E1B4B),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF4F46E5)),
        // Qayta yuklash tugmasi
        actions: [
          if (!state.isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_outlined, size: 22),
              tooltip: 'Yangilash',
              onPressed: () => ref.read(referralProvider.notifier).reload(),
            ),
        ],
      ),
      body: state.isLoading
          ? const AppLoadingWidget()
          : _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, ReferralState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Mukofotlar banneri ──────────────────────────────
          _BenefitsBanner(),
          const SizedBox(height: 24),

          // ── 2. QR kartochkasi (kod mavjud bo'lsa) ─────────────
          if (state.code != null) ...[
            QrCardWidget(
              code: state.code!,
              qrData: state.qrData,
              usedCount: state.usedCount,
            ),
            const SizedBox(height: 16),

            // ── 3. Amallar tugmalari ─────────────────────────────
            Row(
              children: [
                // Nusxalash
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyCode(state.code!),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.copy_outlined,
                        color: Color(0xFF6366F1), size: 18),
                    label: const Text(
                      'Nusxalash',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Ulashish
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _share(state.code!, state.qrData),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text(
                      'Ulashish',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],

          // ── 4. Ajratuvchi ──────────────────────────────────────
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Do'stingizning kodini kiriting",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 20),

          // ── 5. Kod kiritish bo'limi ────────────────────────────
          if (state.hasRedeemed)
            // Allaqachon qo'llagan
            _AlreadyRedeemedBanner()
          else
            _RedeemSection(
              controller: _codeCtrl,
              isRedeeming: state.isRedeeming,
              onRedeem: _redeem,
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Mukofotlar banneri
// ═══════════════════════════════════════════════════════════════
class _BenefitsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sarlavha
          const Row(
            children: [
              Text('🎁', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ikkalangiz 3 kun bepul premium olasiz!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mukofotlar ro'yxati
          _BenefitRow(
            icon: '📲',
            text: "Do'stingiz ilovani yuklab olsin va kodni kiriting",
          ),
          const SizedBox(height: 8),
          _BenefitRow(
            icon: '📅',
            text: "Do'stingiz 1 hafta davomida So'zona ishlatsin",
          ),
          const SizedBox(height: 8),
          _BenefitRow(
            icon: '⭐',
            text:
                'Keyin ikkalangiz 3 kun bepul Premium — AI murabbiy, tabiiy ovoz',
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String icon;
  final String text;

  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Kod kiritish bo'limi
// ═══════════════════════════════════════════════════════════════
class _RedeemSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isRedeeming;
  final VoidCallback onRedeem;

  const _RedeemSection({
    required this.controller,
    required this.isRedeeming,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Izoh
        Text(
          "Do'stingiz So'zona ilovasida referral kodi bo'lsa, uni shu yerga kiriting — ikkalangiz mukofot olasiz.",
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),

        // Kod maydoni
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: Color(0xFF1E1B4B),
          ),
          decoration: InputDecoration(
            hintText: 'SZ-XXXX-XXXX',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              letterSpacing: 2,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Qo'llash tugmasi
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isRedeeming ? null : onRedeem,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isRedeeming
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    "Qo'llash va mukofot olish",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Allaqachon qo'llangan banneri
// ═══════════════════════════════════════════════════════════════
class _AlreadyRedeemedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 28),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kod qo\'llandi — kutilmoqda! ⏳',
                  style: TextStyle(
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '1 hafta davomida So\'zona ishlating — '
                  'keyin ikkalangiz 3 kun bepul premium olasiz! 🎁',
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
