import 'package:tande/models/user_model.dart';

/// A player's registration for a tournament.
///
/// Flow: `pending` (player requested, payment coordinated off-app) →
/// `confirmed` (organizer verified payment) or `rejected`. The player can
/// also `cancelled` their own inscription.
///
/// `waitlisted` is the parking state for a full tournament: when a confirmed
/// spot frees up (cancel or reject) the oldest waitlisted row is promoted to
/// `confirmed` automatically (see `promote_from_waitlist` in migration 0007).
enum InscriptionStatus {
  pending('pending'),
  confirmed('confirmed'),
  rejected('rejected'),
  cancelled('cancelled'),
  waitlisted('waitlisted');

  const InscriptionStatus(this.value);

  final String value;

  // Labels live in `l10n/labels.dart` (models stay UI-free).
  static InscriptionStatus fromValue(String? value) =>
      InscriptionStatus.values.firstWhere(
        (s) => s.value == value,
        orElse: () => InscriptionStatus.pending,
      );
}

class InscriptionModel {
  const InscriptionModel({
    required this.id,
    required this.tournamentId,
    required this.playerId,
    this.status = InscriptionStatus.pending,
    this.teamName = '',
    this.note = '',
    required this.createdAt,
    this.confirmedAt,
    this.player,
  });

  final String id;
  final String tournamentId;
  final String playerId;
  final InscriptionStatus status;
  final String teamName;
  final String note;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  /// Player profile, only populated when the repository joins it
  /// (organizer's request list).
  final UserModel? player;

  bool get isConfirmed => status == InscriptionStatus.confirmed;
  bool get isPending => status == InscriptionStatus.pending;
  bool get isWaitlisted => status == InscriptionStatus.waitlisted;

  factory InscriptionModel.fromJson(Map<String, dynamic> json) {
    return InscriptionModel(
      id: json['id'] as String? ?? '',
      tournamentId: json['tournament_id'] as String? ?? '',
      playerId:
          json['player_id'] as String? ?? json['owner_id'] as String? ?? '',
      status: _statusFromJson(json),
      teamName: json['team_name'] as String? ?? '',
      note: json['note'] as String? ?? '',
      // timestamptz arrives as UTC ISO: convert to local for display.
      createdAt:
          (DateTime.tryParse(
                    json['created_at'] as String? ??
                        json['createdAt'] as String? ??
                        '',
                  ) ??
                  DateTime.now())
              .toLocal(),
      confirmedAt: json['confirmed_at'] == null
          ? null
          : DateTime.tryParse(json['confirmed_at'] as String)?.toLocal(),
      player: json['player'] is Map<String, dynamic>
          ? UserModel.fromJson(json['player'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'player_id': playerId,
      'status': status.value,
      'team_name': teamName,
      'note': note,
      // Unambiguous instant (see TournamentModel.toJson).
      'created_at': createdAt.toUtc().toIso8601String(),
      'confirmed_at': confirmedAt?.toUtc().toIso8601String(),
    };
  }
}

/// Falls back to the legacy `confirmed` boolean when `status` is absent.
InscriptionStatus _statusFromJson(Map<String, dynamic> json) {
  final raw = json['status'];
  if (raw == null && json['confirmed'] == true) {
    return InscriptionStatus.confirmed;
  }
  return InscriptionStatus.fromValue(raw as String?);
}
