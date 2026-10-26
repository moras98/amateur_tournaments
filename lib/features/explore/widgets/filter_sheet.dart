import 'package:tande/core/constants.dart';
import 'package:tande/core/theme/adaptive.dart';
import 'package:tande/data/repositories/providers.dart';
import 'package:tande/features/explore/explore_providers.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:tande/l10n/labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet with sport / distance / availability filters.
Future<void> showExploreFilters(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    // Root navigator: the Explore body runs behind the floating nav
    // capsule, so a branch-anchored sheet would slide underneath the bar.
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) => const _FilterSheet(),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late Set<String> _sports;
  late double? _maxDistanceKm;
  late bool _onlyOpen;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(exploreFiltersProvider);
    // Untouched = the profile-derived default: open with what the player
    // plays preselected (toggling any chip makes the choice explicit).
    final applied =
        filters.sports ??
        ref.read(currentProfileProvider).valueOrNull?.sports ??
        const <String>[];
    _sports = Set.of(applied);
    _maxDistanceKm = filters.maxDistanceKm;
    _onlyOpen = filters.onlyOpen;
  }

  void _apply() {
    final notifier = ref.read(exploreFiltersProvider.notifier);
    notifier.setSports([
      for (final sport in AppConstants.sports)
        if (_sports.contains(sport)) sport,
    ]);
    notifier.setMaxDistance(_maxDistanceKm);
    notifier.setOnlyOpen(_onlyOpen);
    Navigator.of(context).pop();
  }

  void _reset() {
    ref.read(exploreFiltersProvider.notifier).reset();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasLocation = ref.watch(userLocationProvider).valueOrNull != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The drag handle itself comes from bottomSheetTheme
            // (showDragHandle) — drawing one here stacked a second pill.
            const SizedBox(height: 16),
            Row(
              children: [
                Text(l10n.filters, style: theme.textTheme.titleLarge),
                const Spacer(),
                TextButton(onPressed: _reset, child: Text(l10n.reset)),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.sport, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            // Multi-select: any combination of the profile default (or of
            // the user's own picks); "Todos" widens to every sport.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.all),
                  selected: _sports.isEmpty,
                  onSelected: (_) => setState(() => _sports = <String>{}),
                ),
                for (final sport in AppConstants.sports)
                  ChoiceChip(
                    label: Text(l10n.sportLabel(sport)),
                    selected: _sports.contains(sport),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _sports.add(sport);
                      } else {
                        _sports.remove(sport);
                      }
                    }),
                  ),
              ],
            ),
            if (hasLocation) ...[
              const SizedBox(height: 16),
              Text(l10n.distanceFrom, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.any),
                    selected: _maxDistanceKm == null,
                    onSelected: (_) => setState(() => _maxDistanceKm = null),
                  ),
                  for (final km in const [5.0, 10.0, 25.0])
                    ChoiceChip(
                      label: Text('${km.round()} km'),
                      selected: _maxDistanceKm == km,
                      onSelected: (selected) =>
                          setState(() => _maxDistanceKm = selected ? km : null),
                    ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),
              Text(l10n.distanceFrom, style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              // The first fix may have been denied or unavailable: offer an
              // explicit retry instead of leaving distance filters hidden.
              TextButton.icon(
                onPressed: () => ref.invalidate(userLocationProvider),
                icon: const Icon(Icons.my_location),
                label: Text(l10n.updateLocation),
              ),
            ],
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.onlyAvailable),
              trailing: AdaptiveSwitch(
                value: _onlyOpen,
                onChanged: (value) => setState(() => _onlyOpen = value),
              ),
              onTap: () => setState(() => _onlyOpen = !_onlyOpen),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _apply, child: Text(l10n.apply)),
          ],
        ),
      ),
    );
  }
}
