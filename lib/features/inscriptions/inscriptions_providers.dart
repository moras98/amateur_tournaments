import 'package:tande/data/repositories/providers.dart';
import 'package:tande/models/inscription_model.dart';
import 'package:tande/models/tournament_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An inscription joined with its tournament (for the player's list).
class InscriptionEntry {
  const InscriptionEntry({required this.inscription, this.tournament});

  final InscriptionModel inscription;
  final TournamentModel? tournament;

  InscriptionStatus get status => inscription.status;
}

/// All inscriptions made by the signed-in player, newest first.
final myInscriptionsProvider = FutureProvider<List<InscriptionEntry>>((
  ref,
) async {
  final session = ref.watch(authStateProvider);
  if (session == null) return const [];

  final inscriptions = await ref
      .watch(inscriptionRepositoryProvider)
      .fetchForPlayer(session.userId);

  final tournamentRepository = ref.watch(tournamentRepositoryProvider);
  final entries = <InscriptionEntry>[];
  for (final inscription in inscriptions) {
    entries.add(
      InscriptionEntry(
        inscription: inscription,
        tournament: await tournamentRepository.fetchById(
          inscription.tournamentId,
        ),
      ),
    );
  }
  return entries;
});
