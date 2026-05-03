// lib/features/auth/presentation/screens/forgot_password_screen.dart
// ✅ RESPONSIVE FIX:
//   - Column(mainAxisAlignment: center) → Expanded + SingleChildScrollView
//   - keyboardDismissBehavior qo'shildi — klaviatura drag bilan yopiladi
//   - MediaQuery.padding.bottom — nav bar ostida qolmaydi

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authNotifierProvider.notifier)
        .resetPassword(email: _emailCtrl.text.trim());
    if (mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Parolni tiklash')),
      body: _sent ? _buildSuccess(context, bottomPad) : _buildForm(bottomPad),
    );
  }

  // ── Muvaffaqiyat holati ──
  Widget _buildSuccess(BuildContext context, double bottomPad) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 40, 24, bottomPad + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.mark_email_read_outlined,
            size: 72,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          const Text(
            'Email yuborildi!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${_emailCtrl.text} manziliga parol tiklash havolasi yuborildi.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Orqaga'),
          ),
        ],
      ),
    );
  }

  // ── Forma holati ──
  Widget _buildForm(double bottomPad) {
    return SingleChildScrollView(
      // ✅ klaviatura drag bilan yopiladi
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(24, 40, 24, bottomPad + 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Icon(
              Icons.lock_reset_rounded,
              size: 56,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 24),
            Text(
              'Emailingizni kiriting',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Parol tiklash havolasini yuboramiz.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) => v == null || !v.contains('@')
                  ? 'To\'g\'ri email kiriting'
                  : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Yuborish'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Orqaga'),
            ),
          ],
        ),
      ),
    );
  }
}
