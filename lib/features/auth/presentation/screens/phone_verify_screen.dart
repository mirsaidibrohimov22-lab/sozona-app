// lib/features/auth/presentation/screens/phone_verify_screen.dart
// So'zona — OTP tasdiqlash ekrani
// 6 xonali kodni kiritish

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/auth/presentation/widgets/otp_input.dart';
import 'package:my_first_app/core/router/route_names.dart';

/// OTP tasdiqlash ekrani
class PhoneVerifyScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const PhoneVerifyScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  ConsumerState<PhoneVerifyScreen> createState() => _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState extends ConsumerState<PhoneVerifyScreen> {
  String _otpCode = '';
  late String _currentVerificationId;

  int _resendSeconds = 60;
  Timer? _resendTimer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _canResend = false;
    _resendTimer?.cancel();

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) return;

    ref.read(authNotifierProvider.notifier).clearFailure();

    await ref.read(authNotifierProvider.notifier).verifyOtp(
          verificationId: _currentVerificationId,
          otpCode: _otpCode,
        );
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    ref.read(authNotifierProvider.notifier).clearFailure();

    final newVerificationId = await ref
        .read(authNotifierProvider.notifier)
        .signInWithPhone(phoneNumber: widget.phoneNumber);

    if (newVerificationId != null && mounted) {
      _currentVerificationId = newVerificationId;
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yangi kod yuborildi')),
      );
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!mounted) return;
      if (next.status == AuthStatus.authenticated) {
        if (next.user?.isTeacher == true) {
          context.go(RoutePaths.teacherDashboard);
        } else {
          context.go(RoutePaths.studentHome);
        }
      } else if (next.status == AuthStatus.profileIncomplete) {
        context.go(RoutePaths.setupProfile);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      // ✅ TUZATILGAN: SingleChildScrollView — overflow yo'qoladi
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.spacingLg),

              // Telefon ikonkasi
              const Icon(
                Icons.sms_outlined,
                size: 64,
                color: AppColors.primary,
              ),

              const SizedBox(height: AppSizes.spacingLg),

              // Sarlavha
              Text(
                'Kodni kiriting',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.spacingSm),

              Text(
                '${widget.phoneNumber} raqamiga\n6 xonali kod yuborildi',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.spacingXl),

              // Xatolik xabari
              if (authState.failure != null)
                Container(
                  padding: const EdgeInsets.all(AppSizes.spacingMd),
                  margin: const EdgeInsets.only(bottom: AppSizes.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Text(
                    authState.failure!.message,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),

              // OTP input
              OtpInputWidget(
                length: 6,
                onCompleted: (code) {
                  _otpCode = code;
                  _verifyOtp();
                },
                onChanged: (code) {
                  _otpCode = code;
                },
              ),

              const SizedBox(height: AppSizes.spacingXl),

              // Tasdiqlash tugmasi
              ElevatedButton(
                onPressed: authState.isLoading || _otpCode.length != 6
                    ? null
                    : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Tasdiqlash',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),

              const SizedBox(height: AppSizes.spacingLg),

              // Qayta yuborish
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Kod kelmadimi? ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: _canResend ? _resendCode : null,
                    child: Text(
                      _canResend
                          ? 'Qayta yuborish'
                          : 'Qayta yuborish (${_resendSeconds}s)',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.spacingLg),
            ],
          ),
        ),
      ),
    );
  }
}
