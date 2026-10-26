import 'package:tande/core/constants.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A styled tappable link to a legal document (terms, privacy) — opens in
/// the external browser, like the WhatsApp links.
class LegalLink extends StatelessWidget {
  const LegalLink({
    super.key,
    required this.label,
    required this.url,
    this.style,
  });

  final String label;
  final String url;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Text(
        label,
        style: (style ?? theme.textTheme.bodySmall)?.copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Prefix + tappable terms link on one line (Wrap reflows when narrow).
/// Used by the sign-up checkbox and the social sign-in notice.
class TermsText extends StatelessWidget {
  const TermsText({super.key, required this.prefix, this.style});

  final String prefix;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prefix, style: style ?? Theme.of(context).textTheme.bodySmall),
        LegalLink(
          label: l10n.termsAndConditions,
          url: AppConstants.termsUrl,
          style: style,
        ),
      ],
    );
  }
}

/// The registration checkbox — `SignUpScreen` blocks the first step until
/// it's ticked, so account creation always carries explicit acceptance.
class TermsCheckbox extends StatelessWidget {
  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(l10n.acceptTermsPrefix),
          LegalLink(label: l10n.termsAndConditions, url: AppConstants.termsUrl),
        ],
      ),
    );
  }
}
