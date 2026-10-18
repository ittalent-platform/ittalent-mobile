import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/components/ui/app_checkbox.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('AppCheckbox renders unchecked state and triggers onChanged', (
    WidgetTester tester,
  ) async {
    bool? checked = false;

    await tester.pumpWidget(
      buildTestableWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return AppCheckbox(
              value: checked ?? false,
              onChanged: (val) => setState(() => checked = val),
            );
          },
        ),
      ),
    );

    expect(find.byType(Icon), findsNothing);

    await tester.tap(find.byType(AppCheckbox));
    await tester.pumpAndSettle();

    expect(checked, isTrue);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('AppCheckbox renders with label child and toggles on tap', (
    WidgetTester tester,
  ) async {
    bool? checked = false;

    await tester.pumpWidget(
      buildTestableWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return AppCheckbox(
              value: checked ?? false,
              onChanged: (val) => setState(() => checked = val),
              child: const Text('I agree to the terms'),
            );
          },
        ),
      ),
    );

    expect(find.text('I agree to the terms'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);

    await tester.tap(find.text('I agree to the terms'));
    await tester.pumpAndSettle();

    expect(checked, isTrue);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}
