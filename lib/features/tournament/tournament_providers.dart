import 'package:bracket/data/repositories/providers.dart';
import 'package:bracket/models/inscription_model.dart';
import 'package:bracket/models/tournament_model.dart';
import 'package:bracket/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One tournament by id (`null` when it doesn't exist).
final tournamentProvider = FutureProvider.family<TournamentModel?, String>((
  ref,
  id,
) {
  return ref.watch(tournamentRepositoryProvider).fetchById(id);
});

/// The event's organizer (for contact / WhatsApp).
final organizerProvider = FutureProvider.family<UserModel?, String>((
  ref,
  ownerId,
) {
  return ref.watch(profileRepositoryProvider).fetchById(ownerId);
});

/// The signed-in player's inscription for a tournament.
///
/// `null` when signed out or not registered. Re-watched after registering.
final myInscriptionProvider = FutureProvider.family<InscriptionModel?, String>((
  ref,
  tournamentId,
) async {
  final session = ref.watch(authStateProvider);
  if (session == null) return null;
  return ref
      .watch(inscriptionRepositoryProvider)
      .fetchForPlayerAndTournament(
        playerId: session.userId,
        tournamentId: tournamentId,
      );
});
