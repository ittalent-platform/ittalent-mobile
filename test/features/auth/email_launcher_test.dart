import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/auth/utils/email_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  group('launchEmailApp Tests', () {
    testWidgets('launches mailto scheme when canLaunch returns true', (
      WidgetTester tester,
    ) async {
      Uri? launchedUri;
      LaunchMode? launchMode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => launchEmailApp(
                    context,
                    email: 'candidate@company.com',
                    canLaunchUrlChecker: (uri) async => uri.scheme == 'mailto',
                    urlLauncher:
                        (uri, {mode = LaunchMode.platformDefault}) async {
                          launchedUri = uri;
                          launchMode = mode;
                          return true;
                        },
                  ),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(launchedUri, Uri(scheme: 'mailto'));
      expect(launchMode, LaunchMode.externalApplication);
    });

    testWidgets(
      'falls back to Gmail web inbox when mailto fails for @gmail.com',
      (WidgetTester tester) async {
        Uri? launchedUri;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => launchEmailApp(
                      context,
                      email: 'alex.dev@gmail.com',
                      canLaunchUrlChecker: (uri) async => uri.scheme == 'https',
                      urlLauncher:
                          (uri, {mode = LaunchMode.platformDefault}) async {
                            launchedUri = uri;
                            return true;
                          },
                    ),
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(launchedUri, Uri.parse('https://mail.google.com'));
      },
    );

    testWidgets(
      'falls back to Outlook web inbox when mailto fails for @outlook.com',
      (WidgetTester tester) async {
        Uri? launchedUri;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => launchEmailApp(
                      context,
                      email: 'alex.dev@outlook.com',
                      canLaunchUrlChecker: (uri) async => uri.scheme == 'https',
                      urlLauncher:
                          (uri, {mode = LaunchMode.platformDefault}) async {
                            launchedUri = uri;
                            return true;
                          },
                    ),
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(launchedUri, Uri.parse('https://outlook.live.com'));
      },
    );

    testWidgets(
      'displays SnackBar feedback when neither native nor webmail can open',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => launchEmailApp(
                      context,
                      email: 'custom@private-server.org',
                      canLaunchUrlChecker: (_) async => false,
                      urlLauncher: (
                        _, {
                        mode = LaunchMode.platformDefault,
                      }) async => false,
                    ),
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Could not open email app. Please check your inbox manually.',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
