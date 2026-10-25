import 'package:bracket/data/repositories/mock/mock_store.dart';
import 'package:bracket/data/repositories/providers.dart';
import 'package:bracket/features/auth/login_screen.dart';
import 'package:bracket/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

void main() {
  testWidgets('app boots into the Explore tab', (tester) async {
    await tester.pumpWidget(appHarness());
    await tester.pumpAndSettle();

    // Bottom navigation renders every root destination; the indexed shell
    // keeps all branches alive, so each screen's app bar title also shows.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));

    // Explore: search bar + map (fake tiles, no network).
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(BracketApp), findsOneWidget);
  });

  testWidgets('tapping a tab switches the root destination', (tester) async {
    await tester.pumpWidget(appHarness());
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.person_outline),
      ),
    );
    await tester.pumpAndSettle();

    // The demo profile (mock auth starts signed in as the player).
    expect(find.text('Nicolas Perez'), findsOneWidget);
    expect(find.text('@nico'), findsOneWidget);
  });

  testWidgets('social sign-in buttons run the mock OAuth flow', (tester) async {
    await tester.pumpWidget(appHarness(signedIn: false));
    await tester.pumpAndSettle();

    // Explore is public when signed out; the Profile tab opens /login.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.person_outline),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    // The social buttons sit below the fold in the 800x600 test viewport.
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final googleButton = find.widgetWithText(
      OutlinedButton,
      'Continuar con Google',
    );
    expect(googleButton, findsOneWidget);
    expect(find.text('Continuar con Apple'), findsOneWidget);

    await tester.tap(googleButton);
    await tester.pumpAndSettle();

    // Back in the app (profile branch) as the seeded Google account.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('Sofia Ramirez'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(BracketApp)),
    );
    expect(container.read(authStateProvider)!.userId, MockStore.socialGoogleId);
  });

  testWidgets('Apple button signs in via the mock OAuth flow', (tester) async {
    await tester.pumpWidget(appHarness(signedIn: false));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.person_outline),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final appleButton = find.widgetWithText(
      OutlinedButton,
      'Continuar con Apple',
    );
    expect(appleButton, findsOneWidget);

    await tester.tap(appleButton);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('Martin Lopez'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(BracketApp)),
    );
    expect(container.read(authStateProvider)!.userId, MockStore.socialAppleId);
  });
}
