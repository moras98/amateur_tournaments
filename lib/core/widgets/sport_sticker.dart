import 'package:tande/core/sports.dart';
import 'package:flutter/material.dart';

/// The sport glyph in a rounded "sticker".
///
/// A squircle, not Material's circular avatar: the card reads as a tournament
/// tile instead of a contact row, and the same shape survives the Hero flight
/// into the detail header. [onBrand] flips it to white-on-translucent for the
/// gradient/banner header, where scheme roles would disappear.
class SportSticker extends StatelessWidget {
  const SportSticker({
    super.key,
    required this.sport,
    this.size = 44,
    this.onBrand = false,
  });

  final String sport;
  final double size;
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final accent = onBrand ? Colors.white : sportColor(sport);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: onBrand ? 0.18 : 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(
          color: accent.withValues(alpha: onBrand ? 0.36 : 0.28),
        ),
      ),
      child: Icon(sportIcon(sport), color: accent, size: size * 0.52),
    );
  }
}
