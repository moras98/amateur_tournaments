import 'package:bracket/models/inscription_model.dart';
import 'package:bracket/models/tournament_model.dart';
import 'package:bracket/models/user_model.dart';
import 'package:latlong2/latlong.dart';

/// In-memory data shared by the mock repositories.
///
/// A singleton so every repository instance (and therefore every provider)
/// sees the same state. Call [reset] in `setUp` when writing tests.
///
/// [revision] is plain bookkeeping (mutation hook / future reactivity):
/// nothing currently watches it — cross-screen freshness comes from
/// explicit `ref.invalidate` calls at each mutation site.
class MockStore {
  MockStore._() {
    reset();
  }

  static final MockStore instance = MockStore._();

  factory MockStore() => instance;

  /// Seeded demo account behind the mock "Continuar con Google".
  static const socialGoogleId = 'u-social-google';

  /// Seeded demo account behind the mock "Continuar con Apple".
  static const socialAppleId = 'u-social-apple';

  late List<UserModel> profiles;
  late List<TournamentModel> tournaments;
  late List<InscriptionModel> inscriptions;

  /// Account emails keyed by profile id (the mock has no auth table).
  /// Sign-in matches this map — like Supabase's `auth.users` — so renaming
  /// a username can never lock you out of your account.
  late Map<String, String> accountEmails;

  /// The user `MockAuthRepository` starts signed in as (the demo player).
  late String currentUserId;

  /// Bumped on every mutation (see the class doc: not watched by anything).
  int revision = 0;
  late int _idSeq;

  void bump() => revision++;

  /// Unique id for a new entity, e.g. `nextId('u')` → `u-1`.
  String nextId(String prefix) => '$prefix-${++_idSeq}';

  void reset() {
    _idSeq = 0;
    profiles = _seedProfiles();
    tournaments = _seedTournaments();
    inscriptions = _seedInscriptions();
    // Demo logins (see MockAuthRepository's doc). Social demo accounts are
    // included: their password is the provider flow itself, but keeping
    // the email registered resolves their session's address uniformly.
    accountEmails = {
      'u-org-1': 'el_turco@demo.app',
      'u-player-1': 'nico@demo.app',
      'u-player-2': 'lucia@demo.app',
      'u-org-2': 'mariano@demo.app',
      MockStore.socialGoogleId: 'sofia@demo.app',
      MockStore.socialAppleId: 'martin@demo.app',
    };
    currentUserId = player.id;
    revision = 0;
    // Seeded entities use literal ids ('t-1', ...): start runtime ids clear of
    // them so `nextId` can never collide.
    _idSeq = 100;
  }

  /// The profile id registered with [email] (case-insensitive), if any.
  String? profileIdForEmail(String email) {
    final normalized = email.trim().toLowerCase();
    for (final entry in accountEmails.entries) {
      if (entry.value == normalized) return entry.key;
    }
    return null;
  }

  /// Registers [email] as a sign-in address for [profileId] (sign-up).
  void registerAccountEmail(String profileId, String email) {
    accountEmails[profileId] = email.trim().toLowerCase();
  }

  UserModel get player => profiles.firstWhere((p) => p.id == 'u-player-1');
  UserModel get organizer => profiles.firstWhere((p) => p.id == 'u-org-1');

  UserModel? profileById(String id) {
    for (final p in profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  TournamentModel? tournamentById(String id) {
    for (final t in tournaments) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Replaces a tournament in place (used when confirmed counts change).
  void replaceTournament(TournamentModel updated) {
    final index = tournaments.indexWhere((t) => t.id == updated.id);
    if (index >= 0) tournaments[index] = updated;
    bump();
  }
}

List<UserModel> _seedProfiles() => [
  // Modifiable on purpose: sign-up adds profiles at runtime.
  UserModel(
    id: 'u-org-1',
    username: 'el_turco',
    fullName: 'Carlos Ruiz',
    gender: 'male',
    phone: '5491122334455',
    isOrganizer: true,
    sports: ['football', 'padel'],
  ),
  UserModel(
    id: 'u-player-1',
    username: 'nico',
    fullName: 'Nicolas Perez',
    gender: 'male',
    phone: '5491155551234',
    sports: ['football', 'padel'],
  ),
  UserModel(
    id: 'u-player-2',
    username: 'lucia',
    fullName: 'Lucia Gomez',
    gender: 'female',
    phone: '5491166667788',
    sports: ['padel', 'tennis'],
  ),
  UserModel(
    id: 'u-org-2',
    username: 'mariano',
    fullName: 'Mariano Sosa',
    gender: 'male',
    phone: '5491177779900',
    isOrganizer: true,
    sports: ['basketball'],
  ),
  // Social-login demo accounts (mock "Continuar con Google/Apple").
  // Complete profiles: they land straight in the app, while real
  // first-time OAuth users go through /complete-profile.
  UserModel(
    id: MockStore.socialGoogleId,
    username: 'sofia_r',
    fullName: 'Sofia Ramirez',
    gender: 'female',
    birthDate: DateTime(1996, 4, 12),
    sports: ['football', 'padel'],
  ),
  UserModel(
    id: MockStore.socialAppleId,
    username: 'martin_l',
    fullName: 'Martin Lopez',
    gender: 'male',
    birthDate: DateTime(1991, 9, 3),
    sports: ['tennis'],
  ),
];

List<TournamentModel> _seedTournaments() {
  final now = DateTime.now();

  DateTime day(int offset, {int hour = 19, int minute = 0}) =>
      DateTime(now.year, now.month, now.day + offset, hour, minute);

  return [
    TournamentModel(
      id: 't-1',
      ownerId: 'u-org-1',
      sport: 'football',
      kind: 'elimination',
      title: 'Copa Centro 7v7',
      description:
          'Torneo a eliminación directa, 7 contra 7. Con árbitros. '
          'Llegá 30 minutos antes de tu primer partido.',
      prizes: r'Trofeo + $150.000 para el equipo campeón',
      startTime: day(3, hour: 18),
      endTime: day(3, hour: 23),
      inscriptionCost: 25000,
      totalTeams: 16,
      confirmedTeams: 12,
      venueName: 'Complejo Deportivo Centro',
      address: 'Bulevar España 1470',
      city: 'Montevideo',
      location: const LatLng(-34.9040, -56.1660),
      createdAt: now.subtract(const Duration(days: 10)),
    ),
    TournamentModel(
      id: 't-2',
      ownerId: 'u-org-1',
      sport: 'padel',
      kind: 'league',
      title: 'Liga Abierta de Padel Parque Rodó',
      description:
          'Fase de grupos todos contra todos, luego semifinales. '
          'Pelotas incluidas.',
      prizes: 'Trofeo + inscripción gratis al próximo mes',
      startTime: day(6, hour: 9),
      endTime: day(6, hour: 14),
      inscriptionCost: 18000,
      totalTeams: 8,
      confirmedTeams: 8,
      venueName: 'Club Parque Rodó Padel',
      address: 'Av. Sarmiento 1780',
      city: 'Montevideo',
      location: const LatLng(-34.9180, -56.1700),
      createdAt: now.subtract(const Duration(days: 8)),
    ),
    TournamentModel(
      id: 't-3',
      ownerId: 'u-org-2',
      sport: 'basketball',
      kind: 'elimination',
      title: 'Copa Prado 3v3',
      description:
          'Básquet urbano, partidos de 10 minutos. Música y food trucks.',
      prizes: r'Medallas + $100.000',
      startTime: day(10, hour: 17),
      endTime: day(10, hour: 22),
      inscriptionCost: 15000,
      totalTeams: 12,
      confirmedTeams: 5,
      venueName: 'Canchas del Prado',
      address: 'Av. Gral. Flores 3300',
      city: 'Montevideo',
      location: const LatLng(-34.8850, -56.1730),
      createdAt: now.subtract(const Duration(days: 5)),
    ),
    TournamentModel(
      id: 't-4',
      ownerId: 'u-org-2',
      sport: 'tennis',
      kind: 'elimination',
      title: 'Open de Tenis Ciudad Vieja',
      description: 'Cuadro de 32 en individuales. Superficie: cancha dura.',
      prizes: 'Trofeo + vales para equipamiento',
      startTime: day(14, hour: 10),
      endTime: day(15, hour: 18),
      inscriptionCost: 30000,
      totalTeams: 32,
      confirmedTeams: 21,
      venueName: 'Club Ciudad Vieja Tenis',
      address: 'Ituzaingó 1450',
      city: 'Montevideo',
      location: const LatLng(-34.9050, -56.1670),
      createdAt: now.subtract(const Duration(days: 3)),
    ),
    TournamentModel(
      id: 't-5',
      ownerId: 'u-org-1',
      sport: 'football',
      kind: 'league',
      title: 'Futbol 5 Nocturno Cordón',
      description: 'Doble round-robin, 10 equipos. Partidos cada 20 minutos.',
      prizes: 'Trofeo al campeón',
      startTime: day(2, hour: 20),
      endTime: day(2, hour: 23),
      inscriptionCost: 20000,
      totalTeams: 10,
      confirmedTeams: 3,
      venueName: 'Canchas Cordón',
      address: 'Camino Maldonado 1230',
      city: 'Montevideo',
      location: const LatLng(-34.8970, -56.1790),
      createdAt: now.subtract(const Duration(days: 2)),
    ),
    TournamentModel(
      id: 't-6',
      ownerId: 'u-org-2',
      sport: 'padel',
      kind: 'elimination',
      title: 'Abierto de Padel Barrio Sur',
      description: 'Dobles mixtos. Una sola categoría.',
      prizes: 'Trofeo + raquetas',
      startTime: day(20, hour: 10),
      endTime: day(20, hour: 16),
      inscriptionCost: 12000,
      totalTeams: 8,
      confirmedTeams: 1,
      venueName: 'Nave Deportiva Sur',
      address: 'Isla de Flores 1450',
      city: 'Montevideo',
      location: const LatLng(-34.9130, -56.1830),
      createdAt: now,
      status: TournamentStatus.closed,
    ),
  ];
}

List<InscriptionModel> _seedInscriptions() {
  final now = DateTime.now();

  return [
    InscriptionModel(
      id: 'i-1',
      tournamentId: 't-1',
      playerId: 'u-player-1',
      status: InscriptionStatus.confirmed,
      teamName: 'Los Halcones',
      createdAt: now.subtract(const Duration(days: 6)),
      confirmedAt: now.subtract(const Duration(days: 5)),
    ),
    InscriptionModel(
      id: 'i-2',
      tournamentId: 't-1',
      playerId: 'u-player-2',
      status: InscriptionStatus.pending,
      teamName: 'Team Lucia',
      note: 'Pago por transferencia hoy.',
      createdAt: now.subtract(const Duration(hours: 20)),
    ),
    InscriptionModel(
      id: 'i-3',
      tournamentId: 't-5',
      playerId: 'u-player-1',
      status: InscriptionStatus.pending,
      teamName: 'FC Barrio',
      createdAt: now.subtract(const Duration(hours: 5)),
    ),
    InscriptionModel(
      id: 'i-4',
      tournamentId: 't-2',
      playerId: 'u-player-2',
      status: InscriptionStatus.confirmed,
      teamName: 'Dobles Gomez-Perez',
      createdAt: now.subtract(const Duration(days: 7)),
      confirmedAt: now.subtract(const Duration(days: 6)),
    ),
  ];
}
