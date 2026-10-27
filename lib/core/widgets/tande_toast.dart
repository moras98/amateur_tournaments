import 'package:flutter/material.dart';

/// How a toast reads at a glance. The icon carries it; the text stays one line.
enum ToastKind { info, success, error }

/// The app's only transient-feedback widget.
///
/// Material's stock `SnackBar` is the last piece of the UI that looked like a
/// framework default: a full-width dark bar with a raw string. This keeps the
/// platform machinery (ScaffoldMessenger, accessibility, the floating slot that
/// already sits above the nav capsule) and replaces the look: floating pill,
/// 14 radius, `inverseSurface` field, an icon per kind and one line of text.
///
/// Rules (design.md §7): transient success/feedback only — anything
/// destructive or irreversible gets a dialog instead. Failures say what failed
/// *and* the next step.
void showTandeToast(
  BuildContext context,
  String message, {
  ToastKind kind = ToastKind.info,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final scheme = Theme.of(context).colorScheme;
  final (IconData icon, Color tint) = switch (kind) {
    ToastKind.success => (Icons.check_circle_rounded, scheme.primary),
    ToastKind.error => (Icons.error_rounded, scheme.error),
    ToastKind.info => (Icons.info_rounded, scheme.onInverseSurface),
  };

  // Replace instead of queue: a second tap should not make the user wait for
  // the first message to expire.
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        backgroundColor: scheme.inverseSurface,
        duration: Duration(seconds: actionLabel == null ? 3 : 5),
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: scheme.inversePrimary,
                onPressed: onAction,
              ),
        content: Row(
          children: [
            Icon(icon, size: 18, color: tint),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onInverseSurface, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
}
