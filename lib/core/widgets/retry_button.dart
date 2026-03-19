// lib/core/widgets/retry_button.dart
import 'package:flutter/material.dart';

class RetryButton extends StatelessWidget {
  final VoidCallback onRetry;
  final String label;
  const RetryButton({
    super.key,
    required this.onRetry,
    this.label = 'Qayta urinish',
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: Text(label),
    );
  }
}
