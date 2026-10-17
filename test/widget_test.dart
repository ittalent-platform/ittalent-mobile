import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/components/ui/app_badge.dart';
import 'package:ittalent_mobile/components/ui/app_button.dart';
import 'package:ittalent_mobile/components/ui/app_card.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';

void main() {
  testWidgets('AppButton renders with primary variant and triggers callback', (
    WidgetTester tester,
  ) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppButton(
            text: 'Submit application',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Submit application'), findsOneWidget);
    await tester.tap(find.text('Submit application'));
    expect(tapped, isTrue);
  });

  testWidgets('AppBadge renders with correct label and tone', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AppBadge(label: 'Interview', tone: BadgeTone.blocked),
        ),
      ),
    );

    expect(find.text('Interview'), findsOneWidget);
  });

  testWidgets('AppCard renders child with bordered surface', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: AppCard(child: Text('Card Content'))),
      ),
    );

    expect(find.text('Card Content'), findsOneWidget);
  });
}
