import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/components/ui/ittalent_monogram.dart';

void main() {
  testWidgets('ITTalentMonogram renders CustomPaint with default 26 size', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ITTalentMonogram(),
          ),
        ),
      ),
    );

    final monogramFinder = find.byType(ITTalentMonogram);
    expect(monogramFinder, findsOneWidget);

    final size = tester.getSize(monogramFinder);
    expect(size.width, 26.0);
    expect(size.height, 26.0);
    expect(
      find.descendant(
        of: monogramFinder,
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });

  testWidgets('ITTalentMonogram respects custom size and colors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ITTalentMonogram(
              size: 40,
              backgroundColor: Colors.blue,
              glyphColor: Colors.yellow,
            ),
          ),
        ),
      ),
    );

    final monogramFinder = find.byType(ITTalentMonogram);
    expect(monogramFinder, findsOneWidget);

    final size = tester.getSize(monogramFinder);
    expect(size.width, 40.0);
    expect(size.height, 40.0);
  });
}
