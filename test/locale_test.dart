import 'package:bracket/features/explore/explore_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

/// The app follows the phone's locale (main.dart's locale resolution):
/// English device locales render the English copy, while money keeps the
/// Uruguayan-peso layout (`$ 25.000`) in every language.
void main() {
  testWidgets('an English device locale renders English, peso-style money', (
    tester,
  ) async {
    // `appHarness` pins es_UY when called, so override after it and before
    // pumping — `pinTestLocale` sets both locale spellings the app reads.
    final app = appHarness(initialView: ExploreView.list);
    pinTestLocale(tester, const Locale('en'));
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Bottom navigation and search copy in English.
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Sign-ups'), findsOneWidget);
    expect(find.text('Search events, courts, cities'), findsOneWidget);

    // Card spot counts in English… but no Spanish left on screen.
    expect(find.text('4 spots free'), findsOneWidget);
    expect(find.text('Explorar'), findsNothing);

    // …and money still reads `$ 25.000`, not `$25,000`.
    expect(find.text(r'$ 25.000'), findsOneWidget);
  });
}
