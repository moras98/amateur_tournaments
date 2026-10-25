import 'package:flutter/material.dart';

/// Sport-specific icon and marker color.
///
/// Padel and tennis share the racket icon (Material has no padel glyph) and
/// are told apart by color and label.
IconData sportIcon(String sport) => switch (sport) {
  'football' => Icons.sports_soccer,
  'basketball' => Icons.sports_basketball,
  'padel' || 'tennis' => Icons.sports_tennis,
  _ => Icons.sports,
};

Color sportColor(String sport) => switch (sport) {
  'football' => const Color(0xFF2E7D32),
  'padel' => const Color(0xFF0277BD),
  'tennis' => const Color(0xFFEF6C00),
  'basketball' => const Color(0xFF6A1B9A),
  _ => const Color(0xFF455A64),
};
