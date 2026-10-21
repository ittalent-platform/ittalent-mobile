import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ittalent_mobile/components/common/app_toast.dart';
import 'package:ittalent_mobile/theme/app_colors.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';

void main() {
  Future<void> show(WidgetTester tester, {bool error = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppToast(
                ScaffoldMessenger.of(context),
                'Saved',
                error: error,
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  testWidgets('floats on the inverse palette with a check icon', (
    tester,
  ) async {
    await show(tester);

    expect(find.text('Saved'), findsOneWidget);
    expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    final theme = Theme.of(tester.element(find.byType(SnackBar)));
    expect(
      snackBar.behavior ?? theme.snackBarTheme.behavior,
      SnackBarBehavior.floating,
    );
    expect(theme.snackBarTheme.backgroundColor, AppColors.dark.card);
  });

  testWidgets('errors use the alert icon', (tester) async {
    await show(tester, error: true);

    expect(find.byIcon(LucideIcons.circleAlert), findsOneWidget);
    expect(find.byIcon(LucideIcons.circleCheck), findsNothing);
  });
}
