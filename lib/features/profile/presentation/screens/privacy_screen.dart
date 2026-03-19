// QO'YISH: lib/features/profile/presentation/screens/privacy_screen.dart
// So'zona — Maxfiylik siyosati ekrani

import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/app_colors.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maxfiylik siyosati')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _PolicySection(
            title: "Qanday ma'lumotlar saqlanadi?",
            body:
                "So'zona ilovasi foydalanuvchining o'quv jarayonini yaxshilash maqsadida quyidagi ma'lumotlarni saqlaydi:\n\n"
                '• Ism va email/telefon raqam\n'
                "• O'quv natijalar va ballari\n"
                '• Zaif tomonlar tahlili (AI orqali)\n'
                '• Sessiya tarixi\n'
                '• Ovozli yozuvlar (Speaking mashqlari uchun, faqat vaqtincha)',
          ),
          _PolicySection(
            title: "Ma'lumotlar kim bilan ulashiladi?",
            body: "Sizning ma'lumotlaringiz:\n\n"
                '• Firebase (Google) — saqlash va autentifikatsiya uchun\n'
                '• OpenAI/Gemini — AI funksiyalar uchun (anonimlashtirilib yuboriladi)\n'
                "• O'qituvchingiz — agar sinfga qo'shilgan bo'lsangiz\n\n"
                "Ma'lumotlaringiz hech qachon reklama maqsadida sotilmaydi.",
          ),
          _PolicySection(
            title: "Ma'lumotlaringizni boshqarish",
            body: 'Siz istalgan vaqtda:\n\n'
                "• Barcha ma'lumotlaringizni yuklab olishingiz\n"
                "• Hisobingizni va barcha ma'lumotlaringizni o'chirishingiz mumkin\n\n"
                "Buning uchun Sozlamalar > Ma'lumotlarimni yuklab olish bo'limiga o'ting.",
          ),
          _PolicySection(
            title: "Bog'lanish",
            body: 'Savollar uchun: privacy@sozona.app',
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title, body;
  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(height: 1.6)),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
        ],
      );
}
