import 'package:bracket/core/utils/country_code.dart';
import 'package:latlong2/latlong.dart';

/// Lifecycle of a tournament as seen by players.
enum TournamentStatus {
  open('open'),
  full('full'),
  closed('closed');

  const TournamentStatus(this.value);

  final String value;

  // Labels live in `l10n/labels.dart` (models stay UI-free).
  static TournamentStatus fromValue(String? value) => TournamentStatus.values
      .firstWhere((s) => s.value == value, orElse: () => TournamentStatus.open);
}

class TournamentModel {
  const TournamentModel({
    required this.id,
    required this.ownerId,
    required this.sport,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.kind = 'elimination',
    this.description = '',
    this.prizes = '',
    this.inscriptionCost = 0,
    this.currency = defaultCurrency,
    this.totalTeams = 4,
    this.confirmedTeams = 0,
    this.manualConfirmed = 0,
    this.venueName = '',
    this.address = '',
    this.city = '',
    this.location,
    this.status = TournamentStatus.open,
    this.createdAt,
  });

  final String id;
  final String ownerId;
  final String sport; // football | padel | tennis | basketball
  final String kind; // elimination | league
  final String title;
  final String description;
  final String prizes;
  final DateTime startTime;
  final DateTime endTime;
  final double inscriptionCost;

  /// ISO 4217 code the cost is charged in (`UYU`, `EUR`, …): the event
  /// form's selector stores it (audit 4.9) and the card/detail screens
  /// render the amount through `formatCost` with it — an organizer in
  /// Madrid sees euros, not "$ 25".
  final String currency;
  final int totalTeams;

  /// Confirmed inscriptions, read from the `spots_left` view.
  final int confirmedTeams;

  /// Teams the organizer confirmed off the app (in person, WhatsApp,
  /// cash): a stored count (`manual_confirmed` column) because those
  /// players never filed an inscription row here.
  final int manualConfirmed;

  final String venueName;
  final String address;
  final String city;
  final LatLng? location;
  final TournamentStatus status;
  final DateTime? createdAt;

  /// Total confirmed teams: app inscriptions plus the off-app count.
  /// Every "X de Y lugares" and spot check uses this.
  int get totalConfirmed => confirmedTeams + manualConfirmed;

  /// Spots still available. Never negative.
  int get spotsLeft =>
      (totalTeams - totalConfirmed).clamp(0, totalTeams < 0 ? 0 : totalTeams);

  bool get isFull => spotsLeft == 0;
  bool get isOpen => status == TournamentStatus.open && !isFull;

  double? distanceKmFrom(LatLng? origin) {
    if (origin == null || location == null) return null;
    return const Distance().as(LengthUnit.Kilometer, origin, location!);
  }

  TournamentModel copyWith({
    String? id,
    String? ownerId,
    String? sport,
    String? kind,
    String? title,
    String? description,
    String? prizes,
    DateTime? startTime,
    DateTime? endTime,
    double? inscriptionCost,
    String? currency,
    int? totalTeams,
    int? confirmedTeams,
    int? manualConfirmed,
    String? venueName,
    String? address,
    String? city,
    // Closure pattern (see TournamentQuery.copyWith): plain nullable params
    // can't express "reset to null" — `location: () => null` clears the pin.
    LatLng? Function()? location,
    TournamentStatus? status,
    DateTime? Function()? createdAt,
  }) {
    return TournamentModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      sport: sport ?? this.sport,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      description: description ?? this.description,
      prizes: prizes ?? this.prizes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      inscriptionCost: inscriptionCost ?? this.inscriptionCost,
      currency: currency ?? this.currency,
      totalTeams: totalTeams ?? this.totalTeams,
      confirmedTeams: confirmedTeams ?? this.confirmedTeams,
      manualConfirmed: manualConfirmed ?? this.manualConfirmed,
      venueName: venueName ?? this.venueName,
      address: address ?? this.address,
      city: city ?? this.city,
      location: location != null ? location() : this.location,
      status: status ?? this.status,
      createdAt: createdAt != null ? createdAt() : this.createdAt,
    );
  }

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    return TournamentModel(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      sport: json['sport'] as String? ?? 'football',
      kind: json['kind'] as String? ?? 'elimination',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      prizes: json['prizes'] as String? ?? '',
      // PostgREST returns timestamptz as UTC ISO: parse then convert to
      // local so every display path (DateFormat) shows wall-clock time.
      startTime:
          (DateTime.tryParse(json['start_time'] as String? ?? '') ??
                  DateTime.now())
              .toLocal(),
      endTime:
          (DateTime.tryParse(json['end_time'] as String? ?? '') ??
                  DateTime.now())
              .toLocal(),
      // JSON numbers may arrive as int or double.
      inscriptionCost: (json['inscription_cost'] as num?)?.toDouble() ?? 0,
      // Rows written before migration 0009 arrive without the column.
      currency: json['currency'] as String? ?? defaultCurrency,
      totalTeams: (json['total_teams'] as num?)?.toInt() ?? 4,
      confirmedTeams:
          (json['confirmed_teams'] as num?)?.toInt() ??
          (json['inscripted_teams'] as num?)?.toInt() ??
          0,
      manualConfirmed: (json['manual_confirmed'] as num?)?.toInt() ?? 0,
      venueName: json['venue_name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      location: _locationFromJson(json),
      status: TournamentStatus.fromValue(json['status'] as String?),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String)?.toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'sport': sport,
      'kind': kind,
      'title': title,
      'description': description,
      'prizes': prizes,
      // Always send an unambiguous instant (UTC ISO): a naive local string
      // would be cast as UTC by Postgres, shifting the stored time by the
      // device offset.
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'inscription_cost': inscriptionCost,
      'currency': currency,
      'total_teams': totalTeams,
      'manual_confirmed': manualConfirmed,
      'venue_name': venueName,
      'address': address,
      'city': city,
      'latitude': location?.latitude,
      'longitude': location?.longitude,
      'status': status.value,
      'created_at': createdAt?.toUtc().toIso8601String(),
    };
  }

  /// Accepts PostGIS GeoJSON (`{type: Point, coordinates: [lng, lat]}`)
  /// or plain `latitude`/`longitude` fields.
  static LatLng? _locationFromJson(Map<String, dynamic> json) {
    final geo = json['location'];
    if (geo is Map) {
      final coordinates = geo['coordinates'];
      if (coordinates is List && coordinates.length >= 2) {
        final lng = (coordinates[0] as num?)?.toDouble();
        final lat = (coordinates[1] as num?)?.toDouble();
        if (lat != null && lng != null) return LatLng(lat, lng);
      }
    }
    final lat = (json['latitude'] as num?)?.toDouble();
    final lng = (json['longitude'] as num?)?.toDouble();
    if (lat != null && lng != null) return LatLng(lat, lng);
    return null;
  }
}
