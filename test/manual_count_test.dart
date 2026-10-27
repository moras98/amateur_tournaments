import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tande/data/repositories/mock/mock_store.dart';
import 'package:tande/data/repositories/mock/mock_tournament_repository.dart';
import 'package:tande/data/repositories/tournament_repository.dart';
import 'package:tande/features/explore/explore_providers.dart';
import 'package:tande/features/organizer/event_requests_screen.dart';
import 'package:tande/models/tournament_model.dart';

import 'support/harness.dart';

/// Wraps the in-memory repository and makes the off-app write take [delay],
/// like a real UPDATE over the network, while recording what was sent.
class SlowManualRepository implements TournamentRepository {
  SlowManualRepository({
    this.delay = const Duration(milliseconds: 300),
    TournamentRepository? inner,
  }) : _inner = inner ?? MockTournamentRepository();

  final Duration delay;
  final TournamentRepository _inner;

  /// Every value that reached the repository, in order.
  final List<int> sent = [];

  @override
  Future<void> setManualConfirmed(
    TournamentModel tournament,
    int amount,
  ) async {
    sent.add(amount);
    await Future<void>.delayed(delay);
    return _inner.setManualConfirmed(tournament, amount);
  }

  @override
  Future<List<TournamentModel>> fetchTournaments(TournamentQuery query) =>
      _inner.fetchTournaments(query);

  @override
  Future<TournamentModel?> fetchById(String id) => _inner.fetchById(id);

  @override
  Future<List<TournamentModel>> fetchByOwner(String ownerId) =>
      _inner.fetchByOwner(ownerId);

  @override
  Future<TournamentModel> create(TournamentModel tournament) =>
      _inner.create(tournament);

  @override
  Future<TournamentModel> update(TournamentModel tournament) =>
      _inner.update(tournament);

  @override
  Future<void> delete(String id) => _inner.delete(id);

  @override
  Future<String> uploadBanner(String tournamentId, Uint8List bytes) =>
      _inner.uploadBanner(tournamentId, bytes);

  @override
  Future<void> removeBanner(String path) => _inner.removeBanner(path);
}

void main() {
  setUp(MockStore().reset);

  Future<void> openOrganizeTab(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.emoji_events_outlined),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<SlowManualRepository> openEvent(
    WidgetTester tester, {
    Duration delay = const Duration(milliseconds: 300),
  }) async {
    final repository = SlowManualRepository(delay: delay);
    await tester.pumpWidget(
      appHarness(
        signedInAs: 'u-org-1',
        initialView: ExploreView.list,
        tournaments: repository,
      ),
    );
    await tester.pumpAndSettle();
    await openOrganizeTab(tester);
    await tester.tap(find.text('Copa Centro 7v7'));
    await tester.pumpAndSettle();
    expect(find.byType(EventRequestsScreen), findsOneWidget);
    return repository;
  }

  Finder counter(String value) => find.descendant(
    of: find.byKey(const Key('manual-count')),
    matching: find.text(value),
  );

  testWidgets('the off-app counter moves on tap, before the write answers', (
    tester,
  ) async {
    await openEvent(tester);
    expect(find.text('12 de 16 lugares tomados'), findsOneWidget);

    await tester.tap(find.byKey(const Key('manual-add')));
    // A single frame: the write is still in flight (300 ms).
    await tester.pump();

    expect(counter('1'), findsOneWidget);
    // The summary follows the counter, not the other way around.
    expect(find.text('13 de 16 lugares tomados'), findsOneWidget);
    // And nothing blanked out waiting for the network.
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpAndSettle();
    expect(counter('1'), findsOneWidget);
    expect(find.text('13 de 16 lugares tomados'), findsOneWidget);
  });

  testWidgets('quick taps coalesce into the final value, in order', (
    tester,
  ) async {
    final repository = await openEvent(tester);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('manual-add')));
      await tester.pump(const Duration(milliseconds: 20));
    }

    // Three taps are on screen immediately...
    expect(counter('3'), findsOneWidget);
    expect(find.text('15 de 16 lugares tomados'), findsOneWidget);

    await tester.pumpAndSettle();

    // ...and reach the repository as the value in flight plus the final one.
    // The middle value is never sent, so no stale reply can land after it.
    expect(repository.sent, [1, 3]);
    expect(counter('3'), findsOneWidget);
    expect(find.text('15 de 16 lugares tomados'), findsOneWidget);
  });

  testWidgets('the count cannot cross the cupo, even mid-flight', (
    tester,
  ) async {
    await openEvent(tester);

    // Spare capacity is 4 (12 confirmed + 4 = 16).
    for (var i = 0; i < 6; i++) {
      final add = find.byKey(const Key('manual-add'));
      if (tester.widget<IconButton>(add).onPressed == null) break;
      await tester.tap(add);
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(counter('4'), findsOneWidget);
    expect(find.text('16 de 16 lugares tomados'), findsOneWidget);
    // The optimistic status flip matches what the DB trigger will store.
    expect(find.text('COMPLETO'), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
