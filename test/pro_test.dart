import 'package:tande/core/constants.dart';
import 'package:tande/core/router/app_router.dart';
import 'package:tande/data/billing/billing_service.dart';
import 'package:tande/data/billing/mock_billing_service.dart';
import 'package:tande/features/organizer/event_form_screen.dart';
import 'package:tande/features/pro/paywall_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

void main() {
  /// Taps a bottom-nav destination (icons in screen bodies can collide).
  Finder navIcon(IconData icon) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.byIcon(icon),
  );

  /// The paywall's own ListView — the shell keeps every branch's
  /// scrollable alive under the pushed route, so scope by screen.
  Finder paywallScrollable() => find
      .descendant(
        of: find.byType(PaywallScreen),
        matching: find.byType(Scrollable),
      )
      .first;

  final monthly = ProProduct(
    id: AppConstants.proMonthlyId,
    price: 'US\$ 4.99',
    title: 'Tande Pro Monthly',
  );
  final yearly = ProProduct(
    id: AppConstants.proYearlyId,
    price: 'US\$ 39.99',
    title: 'Tande Pro Yearly',
  );

  final ctaLabel = AppConstants.proTrialDays == null
      ? 'Suscribirme'
      : 'Probar gratis';

  group('Tande Pro (widgets)', () {
    testWidgets(
      'before Play has products the paywall is informational and free',
      (tester) async {
        await tester.pumpWidget(appHarness(signedInAs: 'u-org-1'));
        await tester.pumpAndSettle();

        // The organizer sees the entry even before Play has the products:
        // it's the product's pitch, not a purchase flow.
        await tester.tap(navIcon(Icons.person_outline));
        await tester.pumpAndSettle();
        final card = find.widgetWithText(ListTile, 'Tande Pro');
        expect(card, findsOneWidget);
        await tester.tap(card);
        await tester.pumpAndSettle();

        // Benefits are on screen in every state; without products the
        // screen says "próximamente" and shows no plans or buy button.
        expect(find.byType(PaywallScreen), findsOneWidget);
        expect(find.text('Torneos activos ilimitados'), findsOneWidget);
        expect(
          find.text('Exportar inscripciones a CSV (planilla lista para Excel)'),
          findsOneWidget,
        );
        expect(
          find.text('Tande Pro se está por lanzar. ¡Volvé pronto!'),
          findsOneWidget,
        );
        expect(find.widgetWithText(FilledButton, ctaLabel), findsNothing);
        expect(find.text('Elegí tu plan'), findsNothing);
        expect(find.text('US\$ 4.99'), findsNothing);
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Creation still opens the plain form — the closed-test invariant.
        await tester.tap(navIcon(Icons.emoji_events_outlined));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        expect(find.byType(EventFormScreen), findsOneWidget);
        expect(find.byType(PaywallScreen), findsNothing);
      },
    );

    testWidgets('paying mode: the profile card buys Pro on the paywall', (
      tester,
    ) async {
      await tester.pumpWidget(
        appHarness(
          signedInAs: 'u-org-1',
          billing: MockBillingService(products: [monthly, yearly], pro: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      final card = find.widgetWithText(ListTile, 'Tande Pro');
      expect(card, findsOneWidget);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.byType(PaywallScreen), findsOneWidget);

      // Both plans show Play's formatted price, plus the trial CTA.
      expect(find.text('US\$ 4.99'), findsOneWidget);
      expect(find.text('US\$ 39.99'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, ctaLabel), findsOneWidget);

      // The mock grants on buy: the paywall flips to the subscribed state.
      await tester.tap(find.widgetWithText(FilledButton, ctaLabel));
      await tester.pumpAndSettle();
      expect(find.text('Ya tenés Tande Pro'), findsOneWidget);
      expect(
        find.text('Tus torneos activos no tienen límite.'),
        findsOneWidget,
      );
    });

    testWidgets('paying mode: restoring without past purchases notes it', (
      tester,
    ) async {
      await tester.pumpWidget(
        appHarness(
          signedInAs: 'u-org-1',
          billing: MockBillingService(products: [monthly, yearly], pro: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(navIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Tande Pro'));
      await tester.pumpAndSettle();

      final restore = find.widgetWithText(TextButton, 'Restaurar compras');
      await tester.scrollUntilVisible(
        restore,
        300,
        scrollable: paywallScrollable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(restore);
      await tester.pumpAndSettle();
      expect(
        find.text('No encontramos compras para restaurar.'),
        findsOneWidget,
      );
      // Still not Pro: the buy CTA is back after the snackbar.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, ctaLabel), findsOneWidget);
    });

    testWidgets('paying mode: the free tier opens the paywall on overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        appHarness(
          signedInAs: 'u-org-1',
          billing: MockBillingService(products: [monthly], pro: false),
        ),
      );
      await tester.pumpAndSettle();

      // u-org-1 already has active events (t-1, t-2): creating one more
      // exceeds the free tier, so the gate shows the paywall instead.
      await tester.tap(navIcon(Icons.emoji_events_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(find.byType(EventFormScreen), findsNothing);
    });

    testWidgets('paying mode: direct create/duplicate links hit the paywall', (
      tester,
    ) async {
      await tester.pumpWidget(
        appHarness(
          signedInAs: 'u-org-1',
          billing: MockBillingService(products: [monthly], pro: false),
        ),
      );
      await tester.pumpAndSettle();

      // Reaching the form only through the Organizar tab was the bypass:
      // a deep link used to open it without any free-tier check.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
        listen: false,
      );
      final router = container.read(routerProvider);

      router.go('/organize/create');
      await tester.pumpAndSettle();
      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(find.byType(EventFormScreen), findsNothing);

      router.go('/organize/duplicate/t-1');
      await tester.pumpAndSettle();
      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(find.byType(EventFormScreen), findsNothing);
    });
  });
}
