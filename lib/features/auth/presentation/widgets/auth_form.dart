// lib/features/auth/presentation/widgets/auth_form.dart
import 'package:flutter/material.dart';

class AuthForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<Widget> fields;
  final Widget submitButton;
  final String? title;

  const AuthForm({
    super.key,
    required this.formKey,
    required this.fields,
    required this.submitButton,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
          ...fields.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: f,
            ),
          ),
          const SizedBox(height: 8),
          submitButton,
        ],
      ),
    );
  }
}
