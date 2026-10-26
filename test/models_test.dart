import 'package:tande/models/inscription_model.dart';
import 'package:tande/models/tournament_model.dart';
import 'package:tande/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('TournamentModel', () {
    test('parses PostGIS GeoJSON location and int inscription cost', () {
      final json = <String, dynamic>{
        'id': 't-1',
        'owner_id': 'u-1',
        'sport': 'padel',
        'kind': 'league',
        'title': 'Test Cup',
        'description': 'A test',
        'start_time': '2026-11-01T18:00:00',
        'end_time': '2026-11-01T22:00:00',
        'inscription_cost': 25000, // int, not double
        'total_teams': 16,
        'confirmed_teams': 12,
        'venue_name': 'Club X',
        'address': 'Calle 1',
        'city': 'Montevideo',
        'location': {
          'type': 'Point',
          'coordinates': [-56.1660, -34.9040], // [lng, lat]
        },
        'status': 'open',
      };

      final tournament = TournamentModel.fromJson(json);

      expect(tournament.inscriptionCost, 25000.0);
      expect(tournament.location, const LatLng(-34.9040, -56.1660));
      expect(tournament.confirmedTeams, 12);
      expect(tournament.spotsLeft, 4);
      expect(tournament.isOpen, isTrue);
      expect(tournament.status, TournamentStatus.open);
    });

    test(
      'sends timestamps as UTC and parses them back to the same instant',
      () {
        // 18:00 wall-clock wherever the device is: the JSON must carry an
        // unambiguous instant (a naive local string would be read as UTC by
        // Postgres, shifting stored times by the device offset).
        final local = DateTime(2026, 11, 1, 18);
        final tournament = TournamentModel(
          id: 't-9',
          ownerId: 'u-1',
          sport: 'football',
          title: 'TZ Cup',
          startTime: local,
          endTime: local.add(const Duration(hours: 3)),
          createdAt: local,
        );

        final json = tournament.toJson();
        expect(json['start_time'], contains('Z')); // UTC, with offset
        expect(json['end_time'], contains('Z'));

        final roundTripped = TournamentModel.fromJson(json);
        expect(roundTripped.startTime, local); // same instant, local display
        expect(roundTripped.endTime, local.add(const Duration(hours: 3)));
        expect(roundTripped.createdAt, local);

        // A timestamptz from PostgREST (offset form) lands on the same
        // instant and is stored local for display — in any device timezone.
        final fromServer = TournamentModel.fromJson({
          ...json,
          'start_time': '2026-11-01T21:00:00+00:00',
        });
        expect(
          fromServer.startTime.toUtc().toIso8601String(),
          '2026-11-01T21:00:00.000Z',
        );
        expect(fromServer.startTime.isUtc, isFalse); // local for display
      },
    );

    test('falls back to latitude/longitude and legacy inscripted_teams', () {
      final tournament = TournamentModel.fromJson({
        'id': 't-2',
        'owner_id': 'u-1',
        'sport': 'football',
        'title': 'Legacy',
        'latitude': -34.6,
        'longitude': -58.4,
        'inscripted_teams': 4,
        'total_teams': 4,
      });

      expect(tournament.location, const LatLng(-34.6, -58.4));
      expect(tournament.confirmedTeams, 4);
      expect(tournament.spotsLeft, 0);
      expect(tournament.isFull, isTrue);
    });

    test('tolerates missing optional fields', () {
      final tournament = TournamentModel.fromJson({'id': 't-3'});

      expect(tournament.sport, 'football');
      expect(tournament.inscriptionCost, 0);
      expect(tournament.location, isNull);
      expect(tournament.spotsLeft, 4);
      expect(tournament.status, TournamentStatus.open);
    });

    test('spotsLeft never goes negative', () {
      final tournament = TournamentModel.fromJson({
        'id': 't-4',
        'total_teams': 4,
        'confirmed_teams': 6,
      });

      expect(tournament.spotsLeft, 0);
    });

    test('manualConfirmed joins the confirmed total and spot math', () {
      final tournament = TournamentModel.fromJson({
        'id': 't-6',
        'total_teams': 16,
        'confirmed_teams': 12,
        'manual_confirmed': 3, // teams confirmed off the app
      });

      expect(tournament.manualConfirmed, 3);
      expect(tournament.totalConfirmed, 15);
      expect(tournament.spotsLeft, 1);

      // Absent key defaults to zero, and the value round-trips.
      final bare = TournamentModel.fromJson({'id': 't-7'});
      expect(bare.manualConfirmed, 0);
      expect(TournamentModel.fromJson(bare.toJson()).manualConfirmed, 0);
    });

    test('copyWith keeps id and createdAt', () {
      final original = TournamentModel.fromJson({
        'id': 't-5',
        'title': 'Old',
        'created_at': '2026-01-01T00:00:00',
      });
      final updated = original.copyWith(title: 'New', confirmedTeams: 2);

      expect(updated.id, 't-5');
      expect(updated.title, 'New');
      expect(updated.confirmedTeams, 2);
      expect(updated.createdAt, original.createdAt);
    });

    test('copyWith resets location and createdAt through closures', () {
      final original = TournamentModel(
        id: 't-1',
        ownerId: 'u-1',
        sport: 'football',
        title: 'Cup',
        startTime: DateTime(2026, 11, 1, 18),
        endTime: DateTime(2026, 11, 1, 21),
        location: const LatLng(-34.9040, -56.1660),
        createdAt: DateTime(2026, 10, 1),
      );

      final cleared = original.copyWith(
        title: 'New',
        location: () => null,
        createdAt: () => null,
      );

      expect(cleared.title, 'New');
      expect(cleared.location, isNull);
      expect(cleared.createdAt, isNull);
      // Omitted closure params keep the current values.
      expect(original.copyWith().location, isNotNull);
      expect(original.copyWith().createdAt, isNotNull);
    });
  });

  group('InscriptionModel', () {
    test('parses snake_case fields and status', () {
      final inscription = InscriptionModel.fromJson({
        'id': 'i-1',
        'tournament_id': 't-1',
        'player_id': 'u-1',
        'status': 'confirmed',
        'team_name': 'Team A',
        'created_at': '2026-10-01T10:00:00',
        'confirmed_at': '2026-10-02T10:00:00',
      });

      expect(inscription.status, InscriptionStatus.confirmed);
      expect(inscription.isConfirmed, isTrue);
      expect(inscription.confirmedAt, isNotNull);
      expect(inscription.teamName, 'Team A');
    });

    test('supports legacy createdAt key and confirmed flag', () {
      final inscription = InscriptionModel.fromJson({
        'id': 'i-2',
        'owner_id': 'u-1',
        'tournament_id': 't-1',
        'createdAt': '2026-10-01T10:00:00',
        'confirmed': true,
      });

      expect(inscription.playerId, 'u-1');
      expect(inscription.createdAt.year, 2026);
      expect(inscription.status, InscriptionStatus.confirmed);
    });

    test('defaults to pending when status is missing', () {
      final inscription = InscriptionModel.fromJson({'id': 'i-3'});

      expect(inscription.status, InscriptionStatus.pending);
      expect(inscription.isPending, isTrue);
    });
  });

  group('UserModel', () {
    test('parses phone and organizer flag', () {
      final user = UserModel.fromJson({
        'id': 'u-1',
        'username': 'nico',
        'full_name': 'Nicolas Perez',
        'phone': '5491155551234',
        'is_organizer': true,
        'sports': ['football', 'padel'],
      });

      expect(user.phone, '5491155551234');
      expect(user.isOrganizer, isTrue);
      expect(user.canBeContacted, isTrue);
      expect(user.sports, ['football', 'padel']);
    });

    test('copyWith does not lose existing values', () {
      const user = UserModel(
        id: 'u-1',
        username: 'nico',
        fullName: 'Nicolas Perez',
        gender: 'male',
        phone: '5491155551234',
      );

      final updated = user.copyWith(fullName: 'Nicolas Perez Jr.');

      expect(updated.username, 'nico');
      expect(updated.phone, '5491155551234');
      expect(updated.fullName, 'Nicolas Perez Jr.');
      expect(updated.isOrganizer, isFalse);
    });

    test('copyWith resets birthDate and avatarUrl through closures', () {
      const user = UserModel(
        id: 'u-1',
        username: 'nico',
        fullName: 'Nicolas Perez',
        gender: 'male',
      );

      final withOptionals = user.copyWith(
        birthDate: () => DateTime(1990, 5, 4),
        avatarUrl: () => 'https://example.com/a.png',
      );
      expect(withOptionals.birthDate, DateTime(1990, 5, 4));
      expect(withOptionals.avatarUrl, 'https://example.com/a.png');

      final cleared = withOptionals.copyWith(
        birthDate: () => null,
        avatarUrl: () => null,
      );
      expect(cleared.birthDate, isNull);
      expect(cleared.avatarUrl, isNull);
      expect(cleared.username, 'nico');
    });
  });
}
