import 'package:flutter/material.dart';

/// Fade + slide-up entrance animation.
///
/// Stagger list items by passing an increasing [delay]; the value is baked
/// into the curve ([Interval]) so no timers are involved — widget tests can
/// `pumpAndSettle` straight through it.
class AnimateIn extends StatelessWidget {
  const AnimateIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.travel = 14,
  });

  final Widget child;

  /// How long to wait before this widget starts animating in.
  final Duration delay;

  /// How far (px) the widget slides up from.
  final double travel;

  static const _duration = Duration(milliseconds: 420);

  @override
  Widget build(BuildContext context) {
    final start = (delay.inMilliseconds / _duration.inMilliseconds).clamp(
      0.0,
      0.9,
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _duration,
      curve: start > 0 ? Interval(start, 1) : Curves.linear,
      builder: (context, t, child) {
        final v = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * travel),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
