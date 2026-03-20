// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Loading Widget
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:my_first_app/core/widgets/sozana_loading_animation.dart';

/// Loading holati — shimmer effekti bilan.
///
/// 3 xil variant:
/// - [AppLoadingWidget.card] — karta shaklidagi shimmer
/// - [AppLoadingWidget.list] — ro'yxat shaklidagi shimmer
/// - [AppLoadingWidget.circular] — SozonaLoadingAnimation spinner
class AppLoadingWidget extends StatelessWidget {
  const AppLoadingWidget({super.key, this.message, this.style});

  /// Loading xabari (ixtiyoriy).
  final String? message;

  /// Animatsiya stili (ixtiyoriy, default: pulse).
  final LoadingStyle? style;

  /// SozonaLoadingAnimation bilan markazlashgan spinner.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SozonaLoadingAnimation(
        message: message,
        style: style ?? LoadingStyle.pulse,
      ),
    );
  }

  /// Karta shaklidagi shimmer loading.
  static Widget card({int count = 3}) {
    return _ShimmerList(
      count: count,
      itemBuilder: (context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 200,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 150,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ro'yxat shaklidagi shimmer loading.
  static Widget list({int count = 5}) {
    return _ShimmerList(
      count: count,
      itemBuilder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList({
    required this.count,
    required this.itemBuilder,
  });

  final int count;
  final Widget Function(BuildContext) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (context, _) => itemBuilder(context),
      ),
    );
  }
}
