import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/auth/utils/email_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  group('launchEmailApp Inbox Launcher Tests', () {
    testWidgets(
      'launches Android Gmail inbox intent for @gmail.com when supported',
      (WidgetTester tester) async {
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
                      email: 'alex.dev@gmail.com',
                      canLaunchUrlChecker: (uri) async {
                        return uri.toString().contains(
                          'package=com.google.android.gm',
                        );
                      },
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

        expect(
          launchedUri,
          Uri.parse(
            'intent:#Intent;action=android.intent.action.MAIN;package=com.google.android.gm;end',
          ),
        );
        expect(launchMode, LaunchMode.externalApplication);
      },
    );

    testWidgets(
      'falls back to Gmail web inbox when native Gmail apps cannot launch',
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
                      canLaunchUrlChecker: (uri) async {
                        return uri.scheme == 'https';
                      },
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
      'launches Outlook web inbox when Outlook app not installed for @outlook.com',
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
      'launches generic system email app inbox for custom corporate domain',
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
                      email: 'hr@techcorp.vn',
                      canLaunchUrlChecker: (uri) async {
                        return uri.toString().contains(
                          'category=android.intent.category.APP_EMAIL',
                        );
                      },
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

        expect(
          launchedUri,
          Uri.parse(
            'intent:#Intent;action=android.intent.action.MAIN;category=android.intent.category.APP_EMAIL;end',
          ),
        );
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
