// lib/features/referral/presentation/widgets/qr_card_widget.dart
// So'zona — Referral QR kartochkasi
// qr_flutter paketi orqali QR code generatsiya qilinadi.
// Kartochka: QR rasm + kod matni + foydalanish statistikasi

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCardWidget extends StatelessWidget {
  /// Ekranda ko'rsatiladigan referral kod (SZ-XXXX-XXXX)
  final String code;

  /// QR ichiga kodlanadigan deep link (sozona://referral?code=...)
  final String qrData;

  /// Bu kodni nechta yangi foydalanuvchi qo'llagan
  final int usedCount;

  const QrCardWidget({
    super.key,
    required this.code,
    required this.qrData,
    required this.usedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── So'zona brendlash sarlavhasi ──────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Center(
              child: Text(
                "So'zona — Do'st tavsiya kodi",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          // ── QR rasm ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 180,
              gapless: true,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF4F46E5),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF1E1B4B),
              ),
            ),
          ),

          // ── Kod matni ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Statistika ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                usedCount == 0
                    ? "Hali hech kim qo'llamagan"
                    : '$usedCount kishi qo\'lladi',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
