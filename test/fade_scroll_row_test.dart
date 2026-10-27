import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tande/core/widgets/fade_scroll_row.dart';

void main() {
  Widget host(List<Widget> children) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: 300, child: FadeScrollRow(children: children)),
      ),
    ),
  );

  // Fixed widths keep the test about the row's behaviour, not about how much
  // room a Chip happens to want in this Flutter version.
  List<Widget> chips(int count) => [
    for (var i = 0; i < count; i++)
      SizedBox(width: 100, height: 40, child: Text('Filtro ${i + 1}')),
  ];

  testWidgets('chips that fit are not faded', (tester) async {
    await tester.pumpWidget(host(chips(2)));
    await tester.pumpAndSettle();

    // Nothing is hidden, so there is no edge to hint at. (Scoped to the row:
    // Material itself puts ShaderMasks in the tree.)
    expect(
      find.descendant(
        of: find.byType(FadeScrollRow),
        matching: find.byType(ShaderMask),
      ),
      findsNothing,
    );
    expect(find.text('Filtro 2'), findsOneWidget);
  });

  testWidgets('an overflowing row fades instead of slicing the last chip', (
    tester,
  ) async {
    await tester.pumpWidget(host(chips(8)));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(FadeScrollRow),
        matching: find.byType(ShaderMask),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the row still scrolls to the hidden chips', (tester) async {
    await tester.pumpWidget(host(chips(8)));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();

    final controller = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .controller!;
    expect(controller.offset, greaterThan(0));
  });
}
