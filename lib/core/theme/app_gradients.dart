import 'package:flutter/material.dart';

/// Signature brand gradients (see `design.md`).
abstract class AppGradients {
  /// Main brand sweep: deep pitch green → emerald → lime hint. Used on
  /// hero headers (auth, profile) where content sits on top in white.
  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E5C3A), Color(0xFF1B8A5A), Color(0xFF3FB877)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Shorter two-stop variant for compact surfaces.
  static const brandSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B8A5A), Color(0xFF3FB877)],
  );
}
