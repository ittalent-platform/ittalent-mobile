import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/components/ui/app_badge.dart';
import 'package:ittalent_mobile/components/ui/app_card.dart';
import 'package:ittalent_mobile/features/applicant/applications/applications_providers.dart';
import 'package:ittalent_mobile/features/applicant/applications/widgets/application_card.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';

void main() {
  setUpAll(() => EasyLocalization.logger.enableLevels = []);

  testWidgets('the status badge sits at the right edge of the card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ApplicationCard(
            item: ApplicationItem(
              id: '507f1f77bcf86cd799439011',
              jobTitle: 'UI',
              companyName: 'Sunrise Apps',
              status: 'rejected',
              submittedAt: DateTime(2026, 10, 7),
            ),
          ),
        ),
      ),
    );

    final card = tester.getRect(find.byType(AppCard));
    final badge = tester.getRect(find.byType(AppBadge));
    // 16px card padding plus the 1px border.
    expect(card.right - badge.right, lessThanOrEqualTo(17));
  });
}
