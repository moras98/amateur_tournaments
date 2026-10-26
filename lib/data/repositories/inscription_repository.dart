import 'package:tande/models/inscription_model.dart';

/// Player registrations and the organizer's confirm/reject decisions.
///
/// Supabase implementation: `SupabaseInscriptionRepository`;
/// mock: `MockInscriptionRepository`.
abstract class InscriptionRepository {
  /// All inscriptions made by [playerId], newest first.
  Future<List<InscriptionModel>> fetchForPlayer(String playerId);

  /// Inscriptions for [tournamentId], joined with the player profile
  /// (used by the organizer's request manager).
  Future<List<InscriptionModel>> fetchForTournament(String tournamentId);

  /// The player's inscription for a specific tournament, if any.
  Future<InscriptionModel?> fetchForPlayerAndTournament({
    required String playerId,
    required String tournamentId,
  });

  /// Creates a `pending` inscription. The player then coordinates payment
  /// with the organizer off-app.
  Future<InscriptionModel> create({
    required String tournamentId,
    required String playerId,
    String teamName = '',
    String note = '',
  });

  /// Organizer marks an inscription as confirmed or rejected.
  Future<InscriptionModel> decide({
    required String inscriptionId,
    required InscriptionStatus status,
  });

  /// Player cancels their own inscription (frees a confirmed spot).
  Future<void> cancel({required String inscriptionId});

  /// Number of confirmed inscriptions for a tournament.
  Future<int> countConfirmed(String tournamentId);
}
