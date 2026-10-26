import 'package:bracket/core/constants.dart';
import 'package:bracket/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the hosted terms in the external browser (like the WhatsApp links).
Future<void> _openTerms() => launchUrl(
  Uri.parse(AppConstants.termsUrl),
  mode: LaunchMode.externalApplication,
);

/// The tappable "Términos y condiciones" link, styled as one.
class _TermsLink extends StatelessWidget {
  const _TermsLink({this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return GestureDetector(
      key: const Key('terms-link'),
      onTap: _openTerms,
      child: Text(
        l10n.termsAndConditions,
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
    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prefix, style: style ?? Theme.of(context).textTheme.bodySmall),
        _TermsLink(style: style),
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
        children: [Text(l10n.acceptTermsPrefix), const _TermsLink()],
      ),
    );
  }
}
