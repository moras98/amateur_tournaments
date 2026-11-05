import 'dart:async';

import 'package:tande/core/theme/adaptive.dart';
import 'package:tande/core/widgets/sport_sticker.dart';
import 'package:tande/core/utils/format.dart';
import 'package:tande/core/utils/nav_geometry.dart';
import 'package:tande/core/widgets/search_capsule.dart';
import 'package:tande/core/widgets/tande_empty_state.dart';
import 'package:tande/core/widgets/tande_toast.dart';
import 'package:tande/core/widgets/tournament_banner.dart';
import 'package:tande/data/repositories/providers.dart';
import 'package:tande/features/organizer/organizer_providers.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:tande/l10n/labels.dart';
import 'package:tande/models/tournament_model.dart';
import 'package:tande/models/user_model.dart';
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

  /// Create. Opens the event form only after the two gates that must come
  /// before it: a contact channel (§4.10-a — a tournament nobody can write
  /// to is a dead product) and, in paying mode, the free-tier allowance.
  /// Before Play has products configured (paying mode off) the Pro check is
  /// a no-op, exactly as before.
  Future<void> _createEvent() async {
    final l10n = AppLocalizations.of(context)!;

    // Gate 1: contact channel. A failed profile load never blocks
    // creation (same rule as the Pro gate below).
    final profile = await _currentProfileOrNull();
    if (!mounted) return;
    if (profile != null && !profile.hasContactChannels) {
      final go = await showConfirmDialog(
        context,
        title: l10n.createEventNoContactTitle,
        message: l10n.createEventNoContactMessage,
        confirmLabel: l10n.createEventNoContactAction,
        icon: Icons.contact_phone_outlined,
      );
      if (go != true || !mounted) return;

      // To the profile form and back (the form pops on save and
      // invalidates currentProfileProvider, so the re-read is fresh).
      await context.push('/complete-profile');
      if (!mounted) return;

      final after = await _currentProfileOrNull();
      if (!mounted) return;
      if (after != null && !after.hasContactChannels) {
        // Still no channel: opening the form would recreate the very dead
        // end this gate exists for.
        showTandeToast(context, l10n.createEventNoContactPending);
        return;
      }
    }

    // Gate 2: free tier — active tournaments an organizer runs without Pro.
    // The same helper guards the direct create/duplicate routes and the
    // form's save (see `canCreateActiveTournament`).
    if (!await canCreateActiveTournament(ref)) {
      if (!mounted) return;
      context.push('/pro');
      return;
    }
    if (!mounted) return;
    context.push('/organize/create');
  }

  /// The signed-in profile, or null on any failure — a load error must
  /// never become a wall in front of event creation.
  Future<UserModel?> _currentProfileOrNull() async {
    try {
      return await ref.read(currentProfileProvider.future);
    } catch (_) {
      return null;
    }
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
              onPressed: _createEvent,
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

    // Same block as the other tabs' empty states: tinted squircle mark,
    // brand copy and one next step (the profile, where the toggle lives).
    return TandeEmptyState(
      icon: Icons.emoji_events_outlined,
      title: l10n.organizerGateTitle,
      body: l10n.organizerGateBody,
      action: FilledButton(
        onPressed: () => context.go('/profile'),
        child: Text(l10n.goToProfile),
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
          // The FAB is already the screen's primary action, so the empty
          // state doesn't repeat a button (TandeEmptyState's rule).
          return TandeEmptyState(
            icon: Icons.emoji_events_outlined,
            title: l10n.noEventsTitle,
            body: l10n.noEventsBody,
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
            // Same top rhythm as Inscripciones (16/4); the bottom keeps the
            // extra room so the FAB never sits on the last card.
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
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
        child: Column(
          children: [
            // The organizer sees their own banners the way players do.
            if (event.bannerPath != null) TournamentBanner(tournament: event),
            // Same skeleton as the inscription card: sticker | identity
            // column (title → date → info line) | status chip on the right.
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SportSticker(sport: event.sport),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatEventDate(event.startTime, end: event.endTime),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Info line: spots in the primary tint (the same
                        // weight the inscriptions give "lugares") plus the
                        // pending-requests pill when there is something to
                        // review.
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              l10n.spotsOf(
                                event.totalConfirmed,
                                event.totalTeams,
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            if (pending > 0) _RequestsBadge(count: pending),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(status: event.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pending-requests pill — the status chip's geometry (radius 8, icon 14,
/// labelSmall 600) in the pending tint, so both pills read as one family.
class _RequestsBadge extends StatelessWidget {
  const _RequestsBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hourglass_top,
            size: 14,
            color: scheme.onTertiaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.requestsCount(count),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onTertiaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tournament status in the chip style the inscriptions use: pill radius,
/// icon + label, tinted per state.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TournamentStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final (
      Color background,
      Color foreground,
      IconData icon,
    ) = switch (status) {
      TournamentStatus.open => (
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
        Icons.lock_open,
      ),
      TournamentStatus.full => (
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.onTertiaryContainer,
        Icons.group_off,
      ),
      TournamentStatus.closed => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
        Icons.lock,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            l10n.tournamentStatus(status),
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
