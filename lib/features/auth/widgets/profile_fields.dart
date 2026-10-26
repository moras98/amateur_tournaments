import 'package:tande/core/constants.dart';
import 'package:tande/core/utils/format.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:tande/l10n/labels.dart';
import 'package:flutter/material.dart';

/// Account-creation password rules (design.md §7 "Password rules"): at
/// least 8 characters with an uppercase, a lowercase and a digit.
abstract final class PasswordRules {
  static bool hasMinLength(String value) => value.length >= 8;
  static bool hasUpper(String value) => value.contains(RegExp(r'[A-Z]'));
  static bool hasLower(String value) => value.contains(RegExp(r'[a-z]'));
  static bool hasDigit(String value) => value.contains(RegExp(r'[0-9]'));

  /// The first failing rule, in order — the field's error message.
  static String? validate(String value, AppLocalizations l10n) {
    if (!hasMinLength(value)) return l10n.pwUseAtLeast8;
    if (!hasUpper(value)) return l10n.pwAddUppercase;
    if (!hasLower(value)) return l10n.pwAddLowercase;
    if (!hasDigit(value)) return l10n.pwAddNumber;
    return null;
  }
}

/// Live ticks for [PasswordRules] under the field: one compact row per
/// rule that fills in (brand check) as it is met.
class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final rules = [
      (PasswordRules.hasMinLength(password), l10n.pwCheckAtLeast8),
      (PasswordRules.hasUpper(password), l10n.pwCheckUppercase),
      (PasswordRules.hasLower(password), l10n.pwCheckLowercase),
      (PasswordRules.hasDigit(password), l10n.pwCheckNumber),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          for (final (met, label) in rules)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  met ? Icons.check : Icons.radio_button_unchecked,
                  size: 14,
                  color: met ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: met ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The username field — the same validator on sign-up and profile edit.
///
/// [isTaken] is the debounced live result of the uniqueness check (the
/// screens own the lookup — `ProfileRepository.isUsernameTaken`); the
/// field re-validates on rebuild, so the flag shows up as the user types.
class UsernameField extends StatelessWidget {
  const UsernameField({
    super.key,
    required this.controller,
    this.isTaken = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool isTaken;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: l10n.usernameLabel,
        helperText: l10n.usernameHelp,
      ),
      validator: (value) {
        final username = (value ?? '').trim();
        if (username.isEmpty) return l10n.usernameRequired;
        if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(username)) {
          return l10n.usernameFormat;
        }
        if (isTaken) return l10n.usernameTaken;
        return null;
      },
    );
  }
}

/// Birth date under a bold section label (design.md §7): a tappable
/// hairline row — `surface` fill, 52 tall, calendar icon — never a
/// floating input title. The adaptive picker lives on the caller (it needs
/// a context and returns the picked date).
class BirthDateField extends StatelessWidget {
  const BirthDateField({super.key, required this.value, required this.onTap});

  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.birthDate, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null ? l10n.tapToChoose : formatDate(value!),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: value == null
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Single-select gender chips (stored as `male`/`female`/`other`); picking
/// the selected one again clears the choice.
class GenderChips extends StatelessWidget {
  const GenderChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      children: [
        for (final option in const ['male', 'female', 'other'])
          ChoiceChip(
            label: Text(l10n.genderLabel(option)),
            selected: selected == option,
            onSelected: (isSelecting) => onChanged(isSelecting ? option : ''),
          ),
      ],
    );
  }
}

/// Multi-select sport chips. ChoiceChip, not FilterChip: only ChoiceChip
/// applies the theme's secondaryLabelStyle — a bold white label — to the
/// selected fill; FilterChip keeps the resting grey on green.
class SportsChips extends StatelessWidget {
  const SportsChips({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final sport in AppConstants.sports)
          ChoiceChip(
            label: Text(l10n.sportLabel(sport)),
            selected: selected.contains(sport),
            onSelected: (_) => onToggle(sport),
          ),
      ],
    );
  }
}
