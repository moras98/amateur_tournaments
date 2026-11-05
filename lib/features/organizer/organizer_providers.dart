import 'package:tande/core/constants.dart';
import 'package:tande/data/repositories/providers.dart';
import 'package:tande/features/explore/explore_providers.dart';
import 'package:tande/features/pro/pro_providers.dart';
import 'package:tande/features/tournament/tournament_providers.dart';
import 'package:tande/models/inscription_model.dart';
import 'package:tande/models/tournament_model.dart';
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

/// Active = not closed and not over yet. This is the unit the free tier
/// counts (`AppConstants.freeActiveTournaments`): a past or manually closed
/// event must not keep an organizer walled out of the next one.
int activeTournamentCount(
  Iterable<TournamentModel> tournaments, {
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  return tournaments
      .where(
        (t) => t.status != TournamentStatus.closed && t.endTime.isAfter(at),
      )
      .length;
}

/// Whether the signed-in organizer may create one more active tournament.
///
/// Paying mode off (Play has no products yet) or Pro → always allowed. A
/// failed profile/tournament load never blocks creation (same rule as the
/// old inline gate).
///
/// This is the single gate shared by the Organizar tab, the direct
/// `/organize/create` route and the event form's save: the old check lived
/// only on the tab, so a deep link to the form (or a stale screen) could
/// create unlimited events without Pro.
Future<bool> canCreateActiveTournament(WidgetRef ref) async {
  final pro = ref.read(proProvider);
  if (!pro.available || pro.isPro) return true;

  // Re-read instead of trusting a cached list: the point of this check is
  // the last one before the insert, when another device may have created
  // an event in the meantime.
  ref.invalidate(myTournamentsProvider);
  List<TournamentModel> tournaments;
  try {
    tournaments = await ref.read(myTournamentsProvider.future);
  } catch (_) {
    return true;
  }
  return activeTournamentCount(tournaments) <
      AppConstants.freeActiveTournaments;
}

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
