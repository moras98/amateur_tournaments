import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Geometry of the floating bottom-nav capsule (design.md §7): the pill sits
/// [kNavCapsuleMargin] off every screen edge and is [kNavCapsuleBarHeight]
/// tall, so its reserved region measures [kNavCapsuleRegionHeight].
///
/// `NavigationBarThemeData.height` mirrors [kNavCapsuleBarHeight].
const double kNavCapsuleMargin = 12;
const double kNavCapsuleBarHeight = 64;
const double kNavCapsuleRegionHeight =
    kNavCapsuleMargin * 2 + kNavCapsuleBarHeight;

/// Bottom clearance for content laid out *behind* the capsule — the Explore
/// tab runs `extendBody`, and its Scaffold reports the bar to the body as
/// bottom padding exactly like a system inset (Scaffold's `_BodyBuilder`),
/// so inside that body [MediaQueryData.padding] already carries the capsule
/// region plus the device's gesture inset. Outside it only the system inset
/// shows there, so the region is topped up — the result is the distance from
/// the bottom of the screen to the top of the pill everywhere.
double navBarClearanceOf(BuildContext context) {
  final media = MediaQuery.of(context);
  return math.max(
    media.padding.bottom,
    kNavCapsuleRegionHeight + media.viewPadding.bottom,
  );
}
