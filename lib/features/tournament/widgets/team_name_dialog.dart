import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Asks for the team name before the inscription is created.
///
/// Why this exists: `InscriptionModel.teamName` is what the organizer sees in
/// their request list (`event_requests_screen`) and what the CSV export
/// carries. The registration used to fill it with the player's full name, so
/// both of those were showing a person where the organizer needs a team
/// ("Los Pibes · capitán: Nico"). Pre-filled with the player's name so the
/// happy path is one tap.
///
/// A `StatefulWidget` owns the controller: creating one for `showDialog` and
/// disposing it right after the `await` breaks during the exit animation.
class TeamNameDialog extends StatefulWidget {
  const TeamNameDialog({super.key, required this.initial});

  final String initial;

  @override
  State<TeamNameDialog> createState() => _TeamNameDialogState();
}

class _TeamNameDialogState extends State<TeamNameDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = l10n.teamNameRequired);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.teamNameTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.teamNameBody,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('team-name-field'),
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              labelText: l10n.teamNameLabel,
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.confirm)),
      ],
    );
  }
}

/// Opens [TeamNameDialog] and returns the chosen name (or `null` if the
/// player backed out).
Future<String?> askTeamName(BuildContext context, {required String initial}) {
  return showAdaptiveDialog<String>(
    context: context,
    builder: (_) => TeamNameDialog(initial: initial),
  );
}
