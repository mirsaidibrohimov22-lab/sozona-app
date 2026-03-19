// lib/features/flashcard/presentation/widgets/flip_card_widget.dart
// So'zona — Flip kartochka widgeti
// 3D ag'darish animatsiyasi — qayta ishlatiluvchi

import 'dart:math';

import 'package:flutter/material.dart';

/// Flip kartochka widgeti — old va orqa tomoni bor
class FlipCardWidget extends StatefulWidget {
  /// Old tomon widget
  final Widget front;

  /// Orqa tomon widget
  final Widget back;

  /// Tashqaridan boshqarish uchun controller
  final FlipCardController? controller;

  /// Ag'darilganda callback
  final ValueChanged<bool>? onFlip;

  /// Animatsiya davomiyligi
  final Duration duration;

  const FlipCardWidget({
    super.key,
    required this.front,
    required this.back,
    this.controller,
    this.onFlip,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Controller bog'lash
    widget.controller?._state = this;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Ag'darish
  void flip() {
    if (_isFlipped) {
      _animController.reverse();
    } else {
      _animController.forward();
    }
    _isFlipped = !_isFlipped;
    widget.onFlip?.call(_isFlipped);
  }

  /// Old tomonga qaytarish
  void reset() {
    if (_isFlipped) {
      _animController.reverse();
      _isFlipped = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isBack = angle > pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: widget.back,
                  )
                : widget.front,
          );
        },
      ),
    );
  }
}

/// FlipCard controller — tashqaridan boshqarish
class FlipCardController {
  _FlipCardWidgetState? _state;

  /// Ag'darish
  void flip() => _state?.flip();

  /// Old tomonga qaytarish
  void reset() => _state?.reset();

  /// Hozir orqa tomonmi?
  bool get isFlipped => _state?._isFlipped ?? false;
}
