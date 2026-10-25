import 'package:bracket/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('text themes carry the bundled Plus Jakarta Sans family', () {
    // ThemeData.fontFamily only re-families the *default* text themes: the
    // text theme passed into the constructor has to carry the family itself,
    // or the whole app renders in the platform default (Roboto) while the
    // bundled asset sits unused.
    for (final theme in <ThemeData>[AppTheme.light, AppTheme.dark]) {
      final styles = <String, TextStyle?>{
        'displaySmall': theme.textTheme.displaySmall,
        'titleLarge': theme.textTheme.titleLarge,
        'titleMedium': theme.textTheme.titleMedium,
        'bodyLarge': theme.textTheme.bodyLarge,
        'bodyMedium': theme.textTheme.bodyMedium,
        'labelLarge': theme.textTheme.labelLarge,
        'labelSmall': theme.textTheme.labelSmall,
      };
      styles.forEach((name, style) {
        expect(style?.fontFamily, 'PlusJakartaSans', reason: name);
      });
    }
  });

  testWidgets('the bundled variable font renders weights distinctly', (
    tester,
  ) async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf'));
    await loader.load();

    Future<double> widthOf(FontWeight weight) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(
              'Inscripciones',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 20,
                fontWeight: weight,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getSize(find.text('Inscripciones')).width;
    }

    final regular = await widthOf(FontWeight.w400);
    final bold = await widthOf(FontWeight.w700);

    expect(regular, greaterThan(0));
    expect(
      bold,
      greaterThan(regular),
      reason: 'the wght axis is not applied — bold would render flat',
    );
  });
}
