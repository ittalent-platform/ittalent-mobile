import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/components/ui/app_menu_group.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';

void main() {
  group('AppMenuGroup Tests', () {
    testWidgets('renders title and children widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AppMenuGroup(
              title: 'MY PROFILE',
              children: [Text('Row 1'), Text('Row 2')],
            ),
          ),
        ),
      );

      expect(find.text('MY PROFILE'), findsOneWidget);
      expect(find.text('Row 1'), findsOneWidget);
      expect(find.text('Row 2'), findsOneWidget);
    });

    testWidgets('renders without title when null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AppMenuGroup(children: [Text('Single Row')]),
          ),
        ),
      );

      expect(find.text('Single Row'), findsOneWidget);
    });
  });
}
