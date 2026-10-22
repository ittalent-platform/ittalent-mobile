import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/components/ui/app_card.dart';
import 'package:ittalent_mobile/features/applicant/applications/widgets/application_skeletons.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget skeleton) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: skeleton,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('detail skeleton mirrors the page and spans the width', (
    tester,
  ) async {
    await pump(tester, const ApplicationDetailSkeleton());

    expect(tester.takeException(), isNull);
    final cards = find.byType(AppCard);
    expect(cards, findsNWidgets(2));
    expect(tester.getSize(cards.first).width, 328);
  });

  testWidgets('history skeleton is one full-width timeline card', (
    tester,
  ) async {
    await pump(tester, const ApplicationHistorySkeleton());

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppCard)).width, 328);
  });
}
