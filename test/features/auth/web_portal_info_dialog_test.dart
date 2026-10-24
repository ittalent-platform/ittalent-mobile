import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/config/env.dart';
import 'package:ittalent_mobile/features/auth/widgets/web_portal_info_dialog.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  Widget buildTestableWidget({String? role, UrlLauncherFn? launcher}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) =>
                      WebPortalInfoDialog(role: role, launcher: launcher),
                );
              },
              child: const Text('Open Dialog'),
            );
          },
        ),
      ),
    );
  }

  testWidgets('WebPortalInfoDialog renders title, role badge, and actions', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget(role: 'recruiter'));

    // Open dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Web Portal Required'), findsOneWidget);
    expect(find.text('Recruiter Account'), findsOneWidget);
    expect(
      find.textContaining('This mobile app is for job applicants only.'),
      findsOneWidget,
    );
    expect(find.text('Dismiss'), findsOneWidget);
    expect(find.text('Open Web'), findsOneWidget);
  });

  testWidgets('WebPortalInfoDialog Dismiss button pops dialog', (tester) async {
    await tester.pumpWidget(buildTestableWidget(role: 'admin'));

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Platform Admin Account'), findsOneWidget);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();

    expect(find.text('Web Portal Required'), findsNothing);
  });

  testWidgets(
    'WebPortalInfoDialog Open Web button invokes launcher with webBaseUrl',
    (tester) async {
      Uri? launchedUri;
      LaunchMode? launchedMode;

      await tester.pumpWidget(
        buildTestableWidget(
          role: 'enterprise_admin',
          launcher: (uri, {mode = LaunchMode.platformDefault}) async {
            launchedUri = uri;
            launchedMode = mode;
            return true;
          },
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Enterprise Admin Account'), findsOneWidget);

      await tester.tap(find.text('Open Web'));
      await tester.pumpAndSettle();

      expect(launchedUri, Uri.parse(AppEnv.webBaseUrl));
      expect(launchedMode, LaunchMode.externalApplication);
      expect(find.text('Web Portal Required'), findsNothing);
    },
  );
}
