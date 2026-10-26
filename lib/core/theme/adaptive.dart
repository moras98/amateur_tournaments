import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Platform adaptation: the app keeps its Material design language, but
/// speaks native Cupertino where iOS users expect it — confirmation alerts,
/// text-input alerts, switches, date/time pickers and page transitions
/// (design.md §7 "Platform adaptation"). Every check goes through
/// [ThemeData.platform], so tests
/// can pin either side.
bool isCupertino(BuildContext context) =>
    Theme.of(context).platform == TargetPlatform.iOS;

/// The app's confirmation dialog on every platform: Material rules on
/// Material platforms (design.md §7 — close (X) button on top instead of a
/// cancel action, icon-circle header, single full-width confirm in `error`
/// for destructive) and a native [CupertinoAlertDialog] with the same
/// close-on-top on iOS (red destructive action).
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
  IconData? icon,
}) {
  if (isCupertino(context)) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoCloseAlert(
        title: title,
        content: Text(message),
        confirmLabel: confirmLabel,
        destructive: destructive,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }

  final theme = Theme.of(context);
  return showDialog<bool>(
    context: context,
    builder: (context) => CloseTopDialog(
      icon: icon ?? (destructive ? Icons.warning_outlined : Icons.info_outline),
      title: title,
      destructive: destructive,
      confirmLabel: confirmLabel,
      onConfirm: () => Navigator.of(context).pop(true),
      body: Text(
        message,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

/// The app's Material dialog shape (design.md §7): cancelling is the
/// close (X) button on top — never a second action — above an icon-circle
/// header, centered copy and a single full-width confirm at the bottom.
class CloseTopDialog extends StatelessWidget {
  const CloseTopDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.onConfirm,
    this.destructive = false,
  });

  final IconData icon;
  final String title;

  /// Whatever sits between the title and the confirm (message, field…).
  final Widget body;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: destructive
                          ? scheme.errorContainer
                          : scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: destructive
                          ? scheme.onErrorContainer
                          : scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                body,
                const SizedBox(height: 24),
                FilledButton(
                  style: destructive
                      ? FilledButton.styleFrom(
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                        )
                      : null,
                  onPressed: onConfirm,
                  child: Text(confirmLabel),
                ),
              ],
            ),
            // Cancel lives here, on top: it eats into the dialog's padding,
            // beside the centered icon circle.
            Positioned(
              top: -8,
              right: -16,
              child: IconButton(
                tooltip: AppLocalizations.of(context)!.cancel,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A native [CupertinoAlertDialog] with the same close-on-top rule
/// (design.md §7): cancelling is the X, so the alert carries only its
/// confirming action. The title keeps extra top room for the button.
class CupertinoCloseAlert extends StatelessWidget {
  const CupertinoCloseAlert({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.onConfirm,
    this.content,
    this.destructive = false,
  });

  final String title;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final Widget? content;

  /// Red destructive action; otherwise the bold default.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CupertinoAlertDialog(
          title: Padding(
            // Room for the close button on top.
            padding: const EdgeInsets.only(top: 16),
            child: Text(title),
          ),
          content: content == null
              ? null
              : Padding(padding: const EdgeInsets.only(top: 6), child: content),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: destructive,
              isDefaultAction: !destructive,
              onPressed: onConfirm,
              child: Text(confirmLabel),
            ),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(
              CupertinoIcons.xmark,
              size: 20,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
      ],
    );
  }
}

/// The same switch on both platforms: Material's [Switch] or the native
/// [CupertinoSwitch] (tinted with the app's primary through the bridged
/// `CupertinoTheme` in `main.dart`).
class AdaptiveSwitch extends StatelessWidget {
  const AdaptiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return isCupertino(context)
        ? CupertinoSwitch(value: value, onChanged: onChanged)
        : Switch(value: value, onChanged: onChanged);
  }
}

/// Date picker: Material's calendar, or the Cupertino wheel in a modal
/// sheet on iOS ("Listo" confirms; a drag-dismiss keeps the wheel's value).
Future<DateTime?> showAdaptiveDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  if (!isCupertino(context)) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }
  return _showCupertinoWheel(
    context,
    mode: CupertinoDatePickerMode.date,
    initial: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
}

/// Date + time (e.g. an event's start): the Cupertino date-and-time wheel
/// in a single sheet on iOS; the Material calendar followed by the clock
/// elsewhere. Returns null when the user cancels any step.
Future<DateTime?> showAdaptiveDateTimePicker(
  BuildContext context, {
  required DateTime initial,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  if (!isCupertino(context)) {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
  return _showCupertinoWheel(
    context,
    mode: CupertinoDatePickerMode.dateAndTime,
    initial: initial,
    firstDate: DateTime(firstDate.year, firstDate.month, firstDate.day),
    // Any time on the last allowed day, like the Material flow.
    lastDate: DateTime(lastDate.year, lastDate.month, lastDate.day, 23, 59),
  );
}

/// The wheel sheet shared by both Cupertino pickers. The wheel updates the
/// result live; dismissing (Listo or drag) keeps the shown value.
Future<DateTime?> _showCupertinoWheel(
  BuildContext context, {
  required CupertinoDatePickerMode mode,
  required DateTime initial,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  // The wheel asserts its initial value sits inside the boundaries.
  var picked = initial.isBefore(firstDate)
      ? firstDate
      : initial.isAfter(lastDate)
      ? lastDate
      : initial;
  await showCupertinoModalPopup<void>(
    context: context,
    builder: (sheetContext) => ColoredBox(
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.systemBackground,
        sheetContext,
      ),
      child: SizedBox(
        height: mode == CupertinoDatePickerMode.dateAndTime ? 420 : 340,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CupertinoButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(AppLocalizations.of(sheetContext)!.done),
                ),
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: mode,
                // 24h in every language, like every time in the app.
                use24hFormat: true,
                initialDateTime: picked,
                minimumDate: firstDate,
                maximumDate: lastDate,
                onDateTimeChanged: (value) => picked = value,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return picked;
}
