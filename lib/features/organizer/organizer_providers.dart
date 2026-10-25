import 'package:bracket/data/repositories/providers.dart';
import 'package:bracket/features/explore/explore_providers.dart';
import 'package:bracket/features/tournament/tournament_providers.dart';
import 'package:bracket/models/inscription_model.dart';
import 'package:bracket/models/tournament_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tournaments owned by the signed-in user (upcoming first, past last).
final myTournamentsProvider = FutureProvider<List<TournamentModel>>((
  ref,
) async {
  final session = ref.watch(authStateProvider);
  if (session == null) return const [];

  final tournaments = await ref
      .watch(tournamentRepositoryProvider)
      .fetchByOwner(session.userId);

  final now = DateTime.now();
  final upcoming = tournaments.where((t) => t.endTime.isAfter(now)).toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
  final past = tournaments.where((t) => !t.endTime.isAfter(now)).toList()
    ..sort((a, b) => b.startTime.compareTo(a.startTime));
  return [...upcoming, ...past];
});

/// Inscriptions of one of the organizer's events, joined with the players.
final tournamentInscriptionsProvider =
    FutureProvider.family<List<InscriptionModel>, String>((ref, tournamentId) {
      return ref
          .watch(inscriptionRepositoryProvider)
          .fetchForTournament(tournamentId);
    });

/// Pending requests for one event (badge on the organizer's event card).
List<InscriptionModel> pendingRequestsOf(List<InscriptionModel>? all) =>
    all?.where((i) => i.isPending).toList() ?? const [];

/// Refreshes everything a confirm/reject, close/reopen or edit can change.
///
/// Takes a [ProviderContainer] (via `ProviderScope.containerOf(context)`
/// before the await) rather than a `WidgetRef`: `ref` throws after the
/// widget is disposed, and these caches must refresh even when the user
/// navigates away while the write is in flight.
///
/// [exploreResultsProvider] is included because every mutation can change
/// what Explore shows: counts/status (decide, close/reopen, edit) and
/// title/dates/pin (edit).
void invalidateOrganizerState(
  ProviderContainer container, {
  required String tournamentId,
}) {
  container
    ..invalidate(tournamentInscriptionsProvider(tournamentId))
    ..invalidate(tournamentProvider(tournamentId))
    ..invalidate(myTournamentsProvider)
    ..invalidate(exploreResultsProvider);
}
