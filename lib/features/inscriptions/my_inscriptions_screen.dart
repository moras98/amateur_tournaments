import 'dart:async';

import 'package:tande/core/widgets/sport_sticker.dart';
import 'package:tande/core/utils/format.dart';
import 'package:tande/core/utils/nav_geometry.dart';
import 'package:tande/core/widgets/search_capsule.dart';
import 'package:tande/features/inscriptions/inscriptions_providers.dart';
import 'package:tande/l10n/generated/app_localizations.dart';
import 'package:tande/l10n/labels.dart';
import 'package:tande/models/inscription_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _StatusFilter { all, pending, confirmed }

/// The signed-in player's inscriptions with live status.
///
/// Statuses: pending (payment coordinated off-app) → confirmed/rejected by
/// the organizer.
class MyInscriptionsScreen extends ConsumerStatefulWidget {
  const MyInscriptionsScreen({super.key});

  @override
  ConsumerState<MyInscriptionsScreen> createState() =>
      _MyInscriptionsScreenState();
}

class _MyInscriptionsScreenState extends ConsumerState<MyInscriptionsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _search = '';
  _StatusFilter _filter = _StatusFilter.all;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Same debounce rhythm as the other search capsules.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _search = value);
    });
  }

  void _searchNow(String value) {
    _debounce?.cancel();
    setState(() => _search = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final results = ref.watch(myInscriptionsProvider);
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      // No app bar: the same floating search capsule as Explore and
      // Organizar (design.md §7) — a pill next to the pill-shaped status
      // chips. The body clears the capsule's region; the bottom is already
      // inset by the floating nav capsule (non-extendBody tab).
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: topInset + kNavCapsuleRegionHeight),
            child: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    // Single scrolling row: a Wrap would stack the chips on a second
                    // (centered) run on narrow phones — filters stay side by side.
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(l10n.filterAll),
                            selected: _filter == _StatusFilter.all,
                            onSelected: (_) =>
                                setState(() => _filter = _StatusFilter.all),
                          ),
                          ChoiceChip(
                            label: Text(l10n.filterPending),
                            selected: _filter == _StatusFilter.pending,
                            onSelected: (_) =>
                                setState(() => _filter = _StatusFilter.pending),
                          ),
                          ChoiceChip(
                            label: Text(l10n.filterConfirmed),
                            selected: _filter == _StatusFilter.confirmed,
                            onSelected: (_) => setState(
                              () => _filter = _StatusFilter.confirmed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: results.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.myLoadError(error)),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () =>
                                  ref.invalidate(myInscriptionsProvider),
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      ),
                      data: (entries) {
                        final visible = entries.where((entry) {
                          return switch (_filter) {
                            _StatusFilter.all => true,
                            _StatusFilter.pending =>
                              entry.status == InscriptionStatus.pending,
                            _StatusFilter.confirmed =>
                              entry.status == InscriptionStatus.confirmed,
                          };
                        }).toList();

                        if (visible.isEmpty) {
                          return entries.isEmpty
                              ? _EmptyOnboarding(
                                  onExplore: () => context.go('/explore'),
                                )
                              : Center(
                                  child: Text(
                                    switch (_filter) {
                                      _StatusFilter.all =>
                                        l10n.emptyInscriptionsAll,
                                      _StatusFilter.pending =>
                                        l10n.emptyInscriptionsPending,
                                      _StatusFilter.confirmed =>
                                        l10n.emptyInscriptionsConfirmed,
                                    },
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                );
                        }

                        // Free-text search (title/venue/city) — same rhythm and
                        // no-match copy as the other capsules.
                        final query = _search.trim().toLowerCase();
                        final filtered = query.isEmpty
                            ? visible
                            : visible.where((entry) {
                                final t = entry.tournament;
                                return t != null &&
                                    (t.title.toLowerCase().contains(query) ||
                                        t.venueName.toLowerCase().contains(
                                          query,
                                        ) ||
                                        t.city.toLowerCase().contains(query));
                              }).toList();
                        if (filtered.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                l10n.searchNoResults(_search),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            ref.invalidate(myInscriptionsProvider);
                            await ref.read(myInscriptionsProvider.future);
                          },
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _InscriptionCard(entry: filtered[index]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SearchCapsule(
              key: const ValueKey('inscriptions-search-capsule'),
              controller: _searchController,
              hintText: l10n.searchMyInscriptions,
              onChanged: _onSearchChanged,
              onSubmitted: _searchNow,
            ),
          ),
        ],
      ),
    );
  }
}

class _InscriptionCard extends StatelessWidget {
  const _InscriptionCard({required this.entry});

  final InscriptionEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tournament = entry.tournament;
    final inscription = entry.inscription;
    final sport = tournament?.sport ?? 'football';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tournament == null
            ? null
            : () => context.push('/tournament/${tournament.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SportSticker(sport: sport),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament?.title ?? l10n.fallbackTitle,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tournament == null
                          ? ''
                          : formatEventDate(
                              tournament.startTime,
                              end: tournament.endTime,
                            ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (tournament != null &&
                        tournament.spotsLeft > 0 &&
                        entry.status == InscriptionStatus.confirmed) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.spotsLeft(tournament.spotsLeft),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: inscription.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final InscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final (
      Color background,
      Color foreground,
      IconData icon,
    ) = switch (status) {
      InscriptionStatus.pending => (
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.onTertiaryContainer,
        Icons.hourglass_top,
      ),
      InscriptionStatus.confirmed => (
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
        Icons.check_circle,
      ),
      InscriptionStatus.rejected => (
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
        Icons.cancel,
      ),
      InscriptionStatus.cancelled => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
        Icons.block,
      ),
      InscriptionStatus.waitlisted => (
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
        Icons.people_outline,
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
            l10n.inscriptionStatus(status),
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

class _EmptyOnboarding extends StatelessWidget {
  const _EmptyOnboarding({required this.onExplore});

  final VoidCallback onExplore;

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
              Icons.confirmation_num_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(l10n.noInscriptionsTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              l10n.noInscriptionsBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onExplore, child: Text(l10n.exploreEvents)),
          ],
        ),
      ),
    );
  }
}
