import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/applicant/applications/applications_providers.dart';
import 'package:ittalent_mobile/features/applicant/applications/applications_screen.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
  });

  group('ApplicationsScreen Widget Tests', () {
    testWidgets(
      'renders applications list without overflow on narrow device (360px)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer(
          overrides: [
            myApplicationsProvider.overrideWith(
              (ref) async => const [
                ApplicationItem(
                  id: 'APP-1029',
                  jobTitle: 'Senior Flutter Developer',
                  companyName: 'FPT Software',
                  status: 'interview',
                  appliedAt: '2 days ago',
                  location: 'Da Nang, Vietnam',
                ),
                ApplicationItem(
                  id: 'APP-1028',
                  jobTitle: 'Full-Stack TypeScript Engineer',
                  companyName: 'VNG Corporation',
                  status: 'reviewed',
                  appliedAt: '1 week ago',
                  location: 'Ho Chi Minh City, Vietnam',
                ),
              ],
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const ApplicationsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Senior Flutter Developer'), findsOneWidget);
        expect(find.text('Full-Stack TypeScript Engineer'), findsOneWidget);
        expect(find.text('Ho Chi Minh City, Vietnam'), findsOneWidget);
        expect(find.text('APP-1028'), findsOneWidget);

        // Verify no exceptions or overflows were thrown
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders gracefully on standard mobile device (390px) without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer(
          overrides: [
            myApplicationsProvider.overrideWith(
              (ref) async => const [
                ApplicationItem(
                  id: 'APP-1028',
                  jobTitle: 'Full-Stack TypeScript Engineer with Long Title',
                  companyName: 'VNG Corporation',
                  status: 'reviewed',
                  appliedAt: '1 week ago',
                  location: 'Ho Chi Minh City, Southern Region, Vietnam',
                ),
              ],
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const ApplicationsScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
