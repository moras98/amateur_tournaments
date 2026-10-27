import 'package:tande/core/utils/csv_export.dart';
import 'package:tande/features/explore/explore_providers.dart';
import 'package:tande/features/organizer/event_form_screen.dart';
import 'package:tande/data/repositories/mock/mock_inscription_repository.dart';
import 'package:tande/data/repositories/mock/mock_store.dart';
import 'package:tande/models/inscription_model.dart';
import 'package:tande/models/tournament_model.dart';
import 'package:tande/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

/// Tande Pro features: CSV export (pure builder) and the waitlist with
/// automatic promotion (mock parity with migration 0007).
void main() {
  setUp(MockStore().reset);

  group('CSV de inscripciones', () {
    String label(InscriptionStatus status) => switch (status) {
      InscriptionStatus.pending => 'Pendiente',
      InscriptionStatus.confirmed => 'Confirmada',
      InscriptionStatus.rejected => 'Rechazada',
      InscriptionStatus.cancelled => 'Cancelada',
      InscriptionStatus.waitlisted => 'En espera',
    };
    String date(DateTime value) => '${value.day}/${value.month}/${value.year}';

    InscriptionModel inscription({
      String team = 'Los Pibes',
      String playerName = 'Nico Pérez',
      String username = 'nico',
      String phone = '59899123456',
      InscriptionStatus status = InscriptionStatus.confirmed,
      String note = '',
      DateTime? confirmedAt,
    }) => InscriptionModel(
      id: 'i-1',
      tournamentId: 't-1',
      playerId: 'u-1',
      status: status,
      teamName: team,
      note: note,
      createdAt: DateTime(2026, 11, 2, 19),
      confirmedAt: status == InscriptionStatus.confirmed
          ? (confirmedAt ?? DateTime(2026, 11, 2, 20))
          : null,
      player: UserModel(
        id: 'u-1',
        username: username,
        fullName: playerName,
        gender: '',
        phone: phone,
      ),
    );

    test('empeza con BOM y usa CRLF (Excel abre acentos bien)', () {
      final csv = buildInscriptionsCsv(
        inscriptions: [inscription()],
        statusLabel: label,
        dateFormat: date,
      );
      expect(csv.startsWith(csvBom), isTrue);
      expect(csv.contains('\r\n'), isTrue);
      // Dos filas: encabezado + una inscripción, con el terminador final.
      expect('\r\n'.allMatches(csv).length, 2);
      expect(csv.contains('Los Pibes'), isTrue);
      expect(csv.contains('Confirmada'), isTrue);
    });

    test('escapa comas, comillas y saltos de línea (RFC 4180)', () {
      final csv = buildInscriptionsCsv(
        inscriptions: [
          inscription(team: 'Los Pibes, "B"', note: 'linea 1\nlinea 2'),
        ],
        statusLabel: label,
        dateFormat: date,
      );
      expect(csv.contains('"Los Pibes, ""B"""'), isTrue);
      expect(csv.contains('"linea 1\nlinea 2"'), isTrue);
      // El salto de línea dentro de comillas no debe abrir una fila nueva.
      expect('\r\n'.allMatches(csv).length, 2);
    });

    test('sin inscripciones devuelve sólo el encabezado', () {
      final csv = buildInscriptionsCsv(
        inscriptions: const [],
        statusLabel: label,
        dateFormat: date,
      );
      expect('\r\n'.allMatches(csv).length, 1);
      expect(csv.contains('Equipo'), isTrue);
      expect(csv.contains('En espera'), isFalse);
    });

    test('el nombre del archivo es seguro y fechado', () {
      final name = csvFileName(
        title: 'Copa Centro — Fútbol 5 / Ñandú',
        now: DateTime(2026, 11, 2),
      );
      expect(name, 'tande-copa-centro-futbol-5-nandu-20261102.csv');
      expect(name.contains(' '), isFalse);
    });

    test('un título vacío no rompe el nombre', () {
      expect(
        csvFileName(title: '   ', now: DateTime(2026, 1, 9)),
        'tande-torneo-20260109.csv',
      );
    });
  });

  group('Lista de espera', () {
    late MockStore store;
    late MockInscriptionRepository inscriptions;

    /// One spot, already taken by `u-a`.
    TournamentModel fullTournament({String status = 'full'}) => TournamentModel(
      id: 't-full',
      ownerId: 'u-org-1',
      sport: 'football5',
      title: 'Copa Llena',
      startTime: DateTime.now().add(const Duration(days: 2)),
      endTime: DateTime.now().add(const Duration(days: 2, hours: 4)),
      totalTeams: 1,
      confirmedTeams: 1,
      status: TournamentStatus.fromValue(status),
    );

    setUp(() {
      store = MockStore()..reset();
      inscriptions = MockInscriptionRepository(store);
      store.tournaments.insert(0, fullTournament());
      store.inscriptions.add(
        InscriptionModel(
          id: 'i-conf',
          tournamentId: 't-full',
          playerId: 'u-a',
          status: InscriptionStatus.confirmed,
          teamName: 'Equipo A',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          confirmedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      );
    });

    test('anotarse en la espera guarda el estado waitlisted', () async {
      final created = await inscriptions.create(
        tournamentId: 't-full',
        playerId: 'u-b',
        teamName: 'Equipo B',
        waitlist: true,
      );
      expect(created.status, InscriptionStatus.waitlisted);
      expect(created.confirmedAt, isNull);
    });

    test('pedir de nuevo devuelve la misma fila, sin duplicar', () async {
      final first = await inscriptions.create(
        tournamentId: 't-full',
        playerId: 'u-b',
        waitlist: true,
      );
      final second = await inscriptions.create(
        tournamentId: 't-full',
        playerId: 'u-b',
        waitlist: true,
      );
      expect(second.id, first.id);
      expect(store.inscriptions.where((i) => i.playerId == 'u-b').length, 1);
    });

    test('rechazar al confirmado promueve al primero de la espera', () async {
      final waiting = await inscriptions.create(
        tournamentId: 't-full',
        playerId: 'u-b',
        teamName: 'Equipo B',
        waitlist: true,
      );

      await inscriptions.decide(
        inscriptionId: 'i-conf',
        status: InscriptionStatus.rejected,
      );

      final promoted = store.inscriptions.firstWhere((i) => i.id == waiting.id);
      expect(promoted.status, InscriptionStatus.confirmed);
      expect(promoted.confirmedAt, isNotNull);
      // El cupo se llenó otra vez: el torneo sigue lleno.
      expect(store.tournamentById('t-full')!.status, TournamentStatus.full);
      expect(store.tournamentById('t-full')!.totalConfirmed, 1);
    });

    test('cancelar el confirmado también promueve', () async {
      final waiting = await inscriptions.create(
        tournamentId: 't-full',
        playerId: 'u-b',
        waitlist: true,
      );

      await inscriptions.cancel(inscriptionId: 'i-conf');

      expect(
        store.inscriptions.firstWhere((i) => i.id == waiting.id).status,
        InscriptionStatus.confirmed,
      );
    });

    test('promueve al más antiguo y deja al otro en la fila', () async {
      final older = await inscriptions.create(
        tournamentId: 't-full',
        playerId: 'u-b',
        waitlist: true,
      );
      final newer = await inscriptions.create(
        tournamentId: 't-full',
        playerId: 'u-c',
        waitlist: true,
      );

      await inscriptions.decide(
        inscriptionId: 'i-conf',
        status: InscriptionStatus.rejected,
      );

      expect(
        store.inscriptions.firstWhere((i) => i.id == older.id).status,
        InscriptionStatus.confirmed,
      );
      expect(
        store.inscriptions.firstWhere((i) => i.id == newer.id).status,
        InscriptionStatus.waitlisted,
      );
    });

    test('con las inscripciones cerradas no promueve a nadie', () async {
      // Cerrar es una decisión explícita del organizador: meterle gente la
      // contradice (paridad con el trigger de la migración 0007).
      store.replaceTournament(
        store
            .tournamentById('t-full')!
            .copyWith(status: TournamentStatus.closed),
      );
      final waiting = await inscriptions.create(
        tournamentId: 't-full',
        playerId: 'u-b',
        waitlist: true,
      );

      await inscriptions.decide(
        inscriptionId: 'i-conf',
        status: InscriptionStatus.rejected,
      );

      expect(
        store.inscriptions.firstWhere((i) => i.id == waiting.id).status,
        InscriptionStatus.waitlisted,
      );
    });

    test('sin nadie en la espera, rechazar no rompe nada', () async {
      await inscriptions.decide(
        inscriptionId: 'i-conf',
        status: InscriptionStatus.rejected,
      );
      expect(store.tournamentById('t-full')!.totalConfirmed, 0);
    });
  });

  group('UI', () {
    testWidgets('un torneo lleno ofrece anotarse en la lista de espera', (
      tester,
    ) async {
      // t-2 está sembrado 8/8 (lleno) y es de pádel, deporte del jugador demo.
      await tester.pumpWidget(appHarness(initialView: ExploreView.list));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Liga Abierta de Padel Parque Rodó').first);
      await tester.pumpAndSettle();

      expect(find.text('Anotarme en lista de espera'), findsOneWidget);

      await tester.tap(find.text('Anotarme en lista de espera'));
      await tester.pumpAndSettle();

      // El nombre del equipo se pide antes de crear la inscripción: es lo que
      // ve el organizador y lo que sale en el CSV.
      expect(find.text('¿Con qué equipo te anotás?'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('team-name-field')),
        'Los Pibes',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
      await tester.pumpAndSettle();

      // Queda en la espera: la barra muestra el estado y ofrece cancelar.
      expect(find.text('En lista de espera'), findsOneWidget);
      expect(find.text('Cancelar inscripción'), findsOneWidget);

      final stored = MockStore().inscriptions.firstWhere(
        (i) => i.teamName == 'Los Pibes',
      );
      expect(stored.status, InscriptionStatus.waitlisted);
    });

    testWidgets('duplicar abre el formulario con los datos del torneo', (
      tester,
    ) async {
      await tester.pumpWidget(
        appHarness(signedInAs: 'u-org-1', initialView: ExploreView.list),
      );
      await tester.pumpAndSettle();

      // Organizar → primer evento del organizador demo (t-1).
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.emoji_events_outlined),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copa Centro 7v7').first);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicar torneo'));
      await tester.pumpAndSettle();

      expect(find.byType(EventFormScreen), findsOneWidget);
      final title = tester.widget<TextFormField>(
        find.byKey(const Key('event-title')),
      );
      expect(title.controller?.text, 'Copa Centro 7v7');
    });
  });
}
