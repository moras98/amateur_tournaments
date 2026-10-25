import 'dart:async';

import 'package:bracket/core/sports.dart';
import 'package:bracket/core/utils/format.dart';
import 'package:bracket/core/utils/nav_geometry.dart';
import 'package:bracket/core/widgets/search_capsule.dart';
import 'package:bracket/data/repositories/providers.dart';
import 'package:bracket/features/organizer/organizer_providers.dart';
import 'package:bracket/l10n/generated/app_localizations.dart';
import 'package:bracket/l10n/labels.dart';
import 'package:bracket/models/tournament_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Sort options for "my events" (applies to the upcoming and past lists).
enum _EventSort {
  date,
  created,
  title;

  String label(AppLocalizations l10n) => switch (this) {
    _EventSort.date => l10n.sortSoonest,
    _EventSort.created => l10n.sortCreated,
    _EventSort.title => l10n.sortTitleAZ,
  };
}

/// Organizer home: my events with spots/requests overview, and creation.
///
/// Players without organizer mode enabled see a gate pointing to their
/// profile (where the toggle lives).
class OrganizerScreen extends ConsumerStatefulWidget {
  const OrganizerScreen({super.key});

  @override
  ConsumerState<OrganizerScreen> createState() => _OrganizerScreenState();
}

class _OrganizerScreenState extends ConsumerState<OrganizerScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _search = '';
  _EventSort _sort = _EventSort.date;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Same debounce rhythm as Explore's search.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _search = value);
    });
  }

  void _searchNow(String value) {
    _debounce?.cancel();
    setState(() => _search = value);
  }

  /// Sort menu — the capsule's trailing control.
  Widget get _sortMenu {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<_EventSort>(
      tooltip: l10n.sortMenu,
      icon: const Icon(Icons.sort),
      onSelected: (sort) => setState(() => _sort = sort),
      itemBuilder: (context) => [
        for (final sort in _EventSort.values)
          PopupMenuItem(
            value: sort,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  child: _sort == sort
                      ? const Icon(Icons.check, size: 18)
                      : null,
                ),
                // Flexible: the menu clamps at ~256px, and the test font
                // lays out wider than Plus Jakarta.
                Flexible(
                  child: Text(
                    sort.label(l10n),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(currentProfileProvider);
    final isOrganizer = profileAsync.valueOrNull?.isOrganizer == true;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      // No app bar: the search row is the same rounded capsule Explore
      // uses (design.md §7), floating at the top — only for organizers,
      // since the gate has nothing to search. The body clears its region
      // (or just the status bar at the gate).
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: isOrganizer ? topInset + kNavCapsuleRegionHeight : topInset,
            ),
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(l10n.loadError(error))),
              data: (profile) {
                if (profile == null) return const SizedBox.shrink();
                if (!profile.isOrganizer) return const _OrganizerGate();
                return _MyEvents(search: _search, sort: _sort);
              },
            ),
          ),
          if (isOrganizer)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SearchCapsule(
                key: const ValueKey('organizer-search-capsule'),
                controller: _searchController,
                hintText: l10n.searchMyEvents,
                onChanged: _onSearchChanged,
                onSubmitted: _searchNow,
                actions: [_sortMenu],
              ),
            ),
        ],
      ),
      floatingActionButton: isOrganizer
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/organize/create'),
              icon: const Icon(Icons.add),
              label: Text(l10n.createEvent),
            )
          : null,
    );
  }
}

class _OrganizerGate extends StatelessWidget {
  const _OrganizerGate();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(l10n.organizerGateTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              l10n.organizerGateBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go('/profile'),
              child: Text(l10n.goToProfile),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyEvents extends ConsumerWidget {
  const _MyEvents({required this.search, required this.sort});

  /// Free-text filter (title, venue, city), already debounced upstream.
  final String search;

  final _EventSort sort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final results = ref.watch(myTournamentsProvider);
    final theme = Theme.of(context);

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.organizerLoadError(error)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.invalidate(myTournamentsProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (events) {
        if (events.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 56,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.noEventsTitle, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noEventsBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final query = search.trim().toLowerCase();
        final filtered = query.isEmpty
            ? events
            : events
                  .where(
                    (t) =>
                        t.title.toLowerCase().contains(query) ||
                        t.venueName.toLowerCase().contains(query) ||
                        t.city.toLowerCase().contains(query),
                  )
                  .toList();
        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                l10n.searchNoResults(search),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final now = DateTime.now();
        final upcoming = filtered.where((t) => t.endTime.isAfter(now)).toList();
        final past = filtered.where((t) => !t.endTime.isAfter(now)).toList();
        // The provider already orders by date (upcoming soonest first,
        // past latest first); the other sorts apply to both sections.
        if (sort != _EventSort.date) {
          int compare(TournamentModel a, TournamentModel b) => switch (sort) {
            _EventSort.created => (b.createdAt ?? b.startTime).compareTo(
              a.createdAt ?? a.startTime,
            ),
            _EventSort.title => a.title.toLowerCase().compareTo(
              b.title.toLowerCase(),
            ),
            _EventSort.date => 0,
          };
          upcoming.sort(compare);
          past.sort(compare);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myTournamentsProvider);
            await ref.read(myTournamentsProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              for (final event in upcoming) ...[
                _EventCard(event: event),
                const SizedBox(height: 12),
              ],
              if (past.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                  child: Text(
                    l10n.pastEvents,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final event in past) ...[
                  _EventCard(event: event),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EventCard extends ConsumerWidget {
  const _EventCard({required this.event});

  final TournamentModel event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final inscriptions = ref
        .watch(tournamentInscriptionsProvider(event.id))
        .valueOrNull;
    final pending = pendingRequestsOf(inscriptions).length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/organize/event/${event.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sportColor(event.sport).withValues(alpha: 0.15),
                ),
                child: Icon(
                  sportIcon(event.sport),
                  color: sportColor(event.sport),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatEventDate(event.startTime, end: event.endTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusBadge(status: event.status),
                        Text(
                          l10n.spotsOf(event.totalConfirmed, event.totalTeams),
                          style: theme.textTheme.labelSmall,
                        ),
                        if (pending > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.hourglass_top,
                                  size: 12,
                                  color: theme.colorScheme.onTertiaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.requestsCount(pending),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onTertiaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TournamentStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final (Color background, Color foreground) = switch (status) {
      TournamentStatus.open => (
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
      ),
      TournamentStatus.full => (
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.onTertiaryContainer,
      ),
      TournamentStatus.closed => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        l10n.tournamentStatus(status),
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
