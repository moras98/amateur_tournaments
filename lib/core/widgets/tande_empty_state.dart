import 'package:flutter/material.dart';

/// The app's empty state.
///
/// Before this there were two copies of the same block: a 56 px grey outline
/// glyph, a title, a paragraph and a button, all centered in dead space. A
/// lone grey icon in an empty screen is the most "unfinished app" thing a
/// screen can show, so the mark sits in a tinted squircle — the same shape
/// language as the sport stickers — and the copy keeps the brand voice.
///
/// Rules: an empty state always offers the next step (a button), unless the
/// screen has its own primary action already visible.
class TandeEmptyState extends StatelessWidget {
  const TandeEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: scheme.primary.withValues(alpha: 0.10),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.16),
                ),
              ),
              child: Icon(icon, size: 34, color: scheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
