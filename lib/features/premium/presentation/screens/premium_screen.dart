// lib/features/premium/presentation/screens/premium_screen.dart
// So'zona — Premium obuna ekrani
// ✅ Hamma uchun pullik (o'zbek bepul premium o'chirildi)
// ✅ Google Play orqali obuna
// ✅ FIX: Promo kod kiritish UI qo'shildi

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/premium/presentation/providers/premium_provider.dart';
import 'package:my_first_app/features/premium/presentation/providers/iap_provider.dart';

// ── Promo kod provider ────────────────────────────────────────
enum PromoStatus { idle, loading, success, error }

class PromoState {
  final PromoStatus status;
  final String? error;
  const PromoState({this.status = PromoStatus.idle, this.error});
  PromoState copyWith(
      {PromoStatus? status, String? error, bool clearError = false}) {
    return PromoState(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PromoNotifier extends StateNotifier<PromoState> {
  final Ref _ref;
  PromoNotifier(this._ref) : super(const PromoState());

  Future<void> redeem(String code) async {
    if (code.trim().isEmpty) return;
    state = state.copyWith(status: PromoStatus.loading, clearError: true);
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('redeemPromoCode');
      await callable.call({'code': code.trim().toUpperCase()});
      // ✅ Server dan foydalanuvchini yangilaymiz — premium darhol ko'rinadi
      await _ref.read(authNotifierProvider.notifier).refreshUserFromServer();
      state = state.copyWith(status: PromoStatus.success);
    } on FirebaseFunctionsException catch (e) {
      String msg;
      switch (e.code) {
        case 'not-found':
          msg = 'Promo kod topilmadi';
          break;
        case 'already-exists':
          msg = 'Bu kodni allaqachon ishlatgansiz';
          break;
        case 'resource-exhausted':
          msg = 'Promo kod limitiga yetdi';
          break;
        case 'failed-precondition':
          msg = 'Promo kod muddati tugagan';
          break;
        default:
          msg = e.message ?? 'Xatolik yuz berdi';
      }
      state = state.copyWith(status: PromoStatus.error, error: msg);
    } catch (_) {
      state =
          state.copyWith(status: PromoStatus.error, error: 'Xatolik yuz berdi');
    }
  }

  void reset() => state = const PromoState();
}

final promoProvider =
    StateNotifierProvider.autoDispose<PromoNotifier, PromoState>(
  (ref) => PromoNotifier(ref),
);

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPremium = ref.watch(hasPremiumProvider);

    if (hasPremium) {
      return const _PremiumActiveScreen();
    }

    return const _PremiumOfferScreen();
  }
}

// ═══════════════════════════════════════════════════════════════
// PREMIUM FAOL — Allaqachon premium
// ═══════════════════════════════════════════════════════════════

class _PremiumActiveScreen extends StatelessWidget {
  const _PremiumActiveScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Toj belgisi
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Premium Faol! 🎉',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Barcha premium imkoniyatlardan foydalanayapsiz!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 36),
              // Premium imkoniyatlar
              ..._premiumFeatures.map((f) => _FeatureRow(
                    icon: f['icon'] as IconData,
                    title: f['title'] as String,
                    subtitle: f['subtitle'] as String,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PREMIUM TAKLIF — Sotib olish ekrani
// ═══════════════════════════════════════════════════════════════

class _PremiumOfferScreen extends ConsumerWidget {
  const _PremiumOfferScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iapState = ref.watch(iapProvider);
    final iap = ref.read(iapProvider.notifier);
    final isLoading = iapState.status == IAPStatus.loading;

    // Xarid natijasini kuzatish
    ref.listen<IAPState>(iapProvider, (_, next) {
      if (next.status == IAPStatus.success && context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Premium faollashdi!'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      } else if (next.status == IAPStatus.error && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Xatolik yuz berdi'),
            backgroundColor: Colors.red,
          ),
        );
        iap.clearStatus();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFFD700).withValues(alpha: 0.35),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.workspace_premium,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "So'zona Premium",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Til o'rganishni keyingi darajaga olib chiqing",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Free vs Premium taqqoslash
              const _CompareCard(),

              const SizedBox(height: 24),

              // Premium imkoniyatlar
              const Text(
                'Premium imkoniyatlar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._premiumFeatures.map((f) => _FeatureRow(
                    icon: f['icon'] as IconData,
                    title: f['title'] as String,
                    subtitle: f['subtitle'] as String,
                    highlighted: true,
                  )),

              const SizedBox(height: 32),

              // Narx kartalari (hamma uchun)
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: CircularProgressIndicator(
                        color: Color(0xFFFFD700), strokeWidth: 2),
                  ),
                ),
              _PriceCard(
                period: 'Oylik',
                price: iap.monthlyPrice,
                pricePerMonth: '${iap.monthlyPrice}/oy',
                isPopular: false,
                onTap: isLoading ? () {} : () => iap.buyMonthly(),
              ),
              const SizedBox(height: 12),
              _PriceCard(
                period: 'Yillik',
                price: iap.yearlyPrice,
                pricePerMonth: '\$2.50/oy',
                isPopular: true,
                saving: '50% tejash',
                onTap: isLoading ? () {} : () => iap.buyYearly(),
              ),
              const SizedBox(height: 12),
              // Tiklash
              Center(
                child: TextButton(
                  onPressed: isLoading ? null : () => iap.restorePurchases(),
                  child: Text(
                    'Oldingi obunani tiklash',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              // ✅ FIX: Promo kod kiritish
              Center(
                child: TextButton.icon(
                  onPressed: isLoading ? null : () => _showPromoDialog(context),
                  icon: const Icon(Icons.card_giftcard,
                      size: 14, color: Color(0xFFFFD700)),
                  label: const Text(
                    'Promo kod bormi?',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  "Google Play orqali to'lov. Istalgan vaqt bekor qilish mumkin.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Promo kod dialog ─────────────────────────────────────────
  void _showPromoDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: _PromoDialog(controller: controller),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PROMO KOD DIALOG
// ═══════════════════════════════════════════════════════════════

class _PromoDialog extends ConsumerWidget {
  final TextEditingController controller;
  const _PromoDialog({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promo = ref.watch(promoProvider);
    final isLoading = promo.status == PromoStatus.loading;
    final isSuccess = promo.status == PromoStatus.success;

    // Muvaffaqiyatli bo'lsa — dialog yopiladi va xabar ko'rsatiladi
    ref.listen<PromoState>(promoProvider, (_, next) {
      if (next.status == PromoStatus.success && context.mounted) {
        Navigator.of(context).pop();
        // Premium screen ham yopiladi — hasPremiumProvider true bo'lgani uchun
        // avtomatik _PremiumActiveScreen ko'rsatiladi
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Premium faollashdi! Barcha imkoniyatlar ochiq.'),
            backgroundColor: Color(0xFF22C55E),
            duration: Duration(seconds: 4),
          ),
        );
      }
    });

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.card_giftcard, color: Color(0xFFFFD700), size: 22),
          SizedBox(width: 8),
          Text(
            'Promo kod',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Telegram bot orqali olgan promo kodingizni kiriting:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            enabled: !isLoading && !isSuccess,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              color: Colors.white,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              hintText: 'XXXXXX',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                letterSpacing: 2,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.07),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFFD700)),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              errorText: promo.status == PromoStatus.error ? promo.error : null,
              errorMaxLines: 2,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading
              ? null
              : () {
                  ref.read(promoProvider.notifier).reset();
                  Navigator.of(context).pop();
                },
          child: Text(
            'Bekor qilish',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.50)),
          ),
        ),
        ElevatedButton(
          onPressed: isLoading
              ? null
              : () {
                  final code = controller.text.trim();
                  if (code.isEmpty) return;
                  ref.read(promoProvider.notifier).redeem(code);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black54,
                  ),
                )
              : const Text(
                  'Faollashtirish',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool highlighted;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: highlighted
                    ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                    : [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
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

class _CompareCard extends StatelessWidget {
  const _CompareCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tekin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.60),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                    width: 1,
                    height: 20,
                    color: Colors.white.withValues(alpha: 0.10)),
                const Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.workspace_premium,
                          color: Color(0xFFFFD700), size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Premium',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Rows
          ..._compareRows.map((row) => _CompareRow(
                label: row['label'] as String,
                free: row['free'] as String,
                premium: row['premium'] as String,
              )),
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final String free;
  final String premium;

  const _CompareRow({
    required this.label,
    required this.free,
    required this.premium,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              premium,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String period;
  final String price;
  final String pricePerMonth;
  final bool isPopular;
  final String? saving;
  final VoidCallback onTap;

  const _PriceCard({
    required this.period,
    required this.price,
    required this.pricePerMonth,
    required this.isPopular,
    this.saving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isPopular
              ? const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                )
              : null,
          border: Border.all(
            color: isPopular
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.15),
          ),
          color: isPopular ? null : Colors.white.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        period,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Mashhur',
                            style: TextStyle(
                              color: Color(0xFF1A0A00),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pricePerMonth,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (saving != null)
                  Text(
                    saving!,
                    style: const TextStyle(
                      color: Color(0xFF4ADE80),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DATA
// ═══════════════════════════════════════════════════════════════

const _premiumFeatures = [
  {
    'icon': Icons.psychology,
    'title': 'Shaxsiy AI Murabbiy',
    'subtitle': 'Zaif nuqtalaringizni aniqlab, shaxsiy reja tuzadi',
  },
  {
    'icon': Icons.record_voice_over,
    'title': 'Tabiiy AI Ovoz (OpenAI)',
    'subtitle': 'Listening va chatda jonli, tabiiy ovoz',
  },
  {
    'icon': Icons.school,
    'title': 'Ilmiy Usullar',
    'subtitle': 'Oxford, Cambridge, Harvard tadqiqotlariga asoslangan',
  },
  {
    'icon': Icons.trending_up,
    'title': 'Chuqur Tahlil',
    'subtitle': 'Har mashq oxirida batafsil shaxsiy tahlil',
  },
  {
    'icon': Icons.block,
    'title': "Reklama Yo'q",
    'subtitle': "Hech qanday reklama, faqat o'rganish",
  },
  {
    'icon': Icons.chat_bubble,
    'title': 'Cheksiz AI Chat',
    'subtitle': "Kunlik limit yo'q, xohlagan vaqt chat qiling",
  },
];

const _compareRows = [
  {'label': 'AI Chat', 'free': '10/kun', 'premium': 'Cheksiz ✓'},
  {'label': 'TTS Ovoz', 'free': 'Gemini', 'premium': 'OpenAI ✓'},
  {'label': 'Shaxsiy tahlil', 'free': '✗', 'premium': '✓'},
  {'label': 'Reklama', 'free': 'Bor', 'premium': "Yo'q ✓"},
  {'label': 'Ilmiy usullar', 'free': '✗', 'premium': '✓'},
  {'label': 'Haftalik reja', 'free': '✗', 'premium': '✓'},
];
