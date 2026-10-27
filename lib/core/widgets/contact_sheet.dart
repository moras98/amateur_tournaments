import 'package:flutter/material.dart';
import 'package:tande/core/utils/contact.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:tande/models/contact_channel.dart';

/// Lets the user pick how to reach someone: WhatsApp, a call, Instagram,
/// Telegram or a link (a Google Form, a club site).
///
/// Returns `true` when a channel opened, `false` when the platform refused
/// it, and `null` when the user dismissed the sheet.
///
/// With a single channel there is nothing to pick — the caller opens it
/// directly instead of paying for a sheet with one row.
Future<bool?> showContactSheet({
  required BuildContext context,
  required String title,
  required List<ContactChannel> channels,
  String message = '',
}) {
  return showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) =>
        _ContactSheet(title: title, channels: channels, message: message),
  );
}

class _ContactSheet extends StatelessWidget {
  const _ContactSheet({
    required this.title,
    required this.channels,
    required this.message,
  });

  final String title;
  final List<ContactChannel> channels;
  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final channel in channels)
              _ChannelTile(channel: channel, message: message, l10n: l10n),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.channel,
    required this.message,
    required this.l10n,
  });

  final ContactChannel channel;
  final String message;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final opened = await openContactChannel(channel, message: message);
            if (!context.mounted) return;
            Navigator.of(context).pop(opened);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: scheme.primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(channel.icon, size: 19, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labelOf(channel, l10n),
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hintOf(channel),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.north_east_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _labelOf(ContactChannel channel, AppLocalizations l10n) {
    if (channel.label.isNotEmpty) return channel.label;
    return switch (channel.kind) {
      ContactKind.whatsapp => l10n.contactWhatsApp,
      ContactKind.call => l10n.contactCall,
      ContactKind.instagram => l10n.contactInstagram,
      ContactKind.telegram => l10n.contactTelegram,
      ContactKind.link => l10n.contactLink,
    };
  }

  /// The second line: what the user is about to open, so a wrong handle is
  /// visible before the tap.
  String _hintOf(ContactChannel channel) {
    return switch (channel.kind) {
      ContactKind.whatsapp || ContactKind.call => '+${channel.target}',
      ContactKind.instagram || ContactKind.telegram => '@${channel.target}',
      ContactKind.link => channel.target,
    };
  }
}
