// lib/core/widgets/app_card.dart
// So'zona — Qayta ishlatiluvchi card widgeti
// ✅ TUZATILDI: AnimatedProgressBar olib tashlandi (animated_counter.dart da bor)
// ✅ TUZATILDI: unused app_colors import olib tashlandi

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_sizes.dart';

/// Qayta ishlatiluvchi card widgeti — zamonaviy, chiroyli
class AppCard extends StatefulWidget {
  /// Card ichidagi content
  final Widget child;

  /// Bosilganda
  final VoidCallback? onTap;

  /// Ichki padding
  final EdgeInsets? padding;

  /// Chegara rangi
  final Color? borderColor;

  /// Fon rangi
  final Color? backgroundColor;

  /// Border radius
  final double? borderRadius;

  /// Soya (elevation)
  final double elevation;

  /// Gradient (ixtiyoriy)
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderColor,
    this.backgroundColor,
    this.borderRadius,
    this.elevation = 0,
    this.gradient,
  });

  /// Oddiy card — border bilan
  factory AppCard.outlined({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? padding,
  }) {
    return AppCard(
      onTap: onTap,
      padding: padding,
      borderColor: const Color(0xFFF1F5F9),
      child: child,
    );
  }

  /// Soyali card
  factory AppCard.elevated({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? padding,
  }) {
    return AppCard(
      onTap: onTap,
      padding: padding,
      elevation: 2,
      child: child,
    );
  }

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) _controller.reverse();
  }

  void _onTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? 16.0;

    Widget card = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: widget.gradient == null
              ? (widget.backgroundColor ?? Colors.white)
              : null,
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: widget.borderColor ?? const Color(0xFFF1F5F9),
            width: 1,
          ),
          boxShadow: [
            // Yumshoq asosiy soya
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            // Qo'shimcha soya (elevation > 0 bo'lsa)
            if (widget.elevation > 0)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: widget.elevation * 6,
                offset: Offset(0, widget.elevation * 2),
              ),
          ],
        ),
        child: Padding(
          padding: widget.padding ?? const EdgeInsets.all(AppSizes.spacingLg),
          child: widget.child,
        ),
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: card,
      );
    }

    return card;
  }
}
