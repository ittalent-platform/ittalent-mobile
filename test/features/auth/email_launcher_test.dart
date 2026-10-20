import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/auth/utils/email_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  group('launchEmailApp Inbox Launcher Tests', () {
    testWidgets(
      'launches native mail client via nativeLauncher when available',
      (WidgetTester tester) async {
        String? targetEmail;
        var nativeInvoked = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => launchEmailApp(
                      context,
                      email: 'alex.dev@gmail.com',
                      nativeLauncher: (email) async {
                        targetEmail = email;
                        nativeInvoked = true;
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

        expect(nativeInvoked, isTrue);
        expect(targetEmail, 'alex.dev@gmail.com');
      },
    );

    testWidgets(
      'falls back to Gmail web inbox when native mail app cannot launch',
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
                      nativeLauncher: (_) async => false,
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
      'launches Outlook web inbox when native app fails for @outlook.com',
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
                      nativeLauncher: (_) async => false,
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
      'launches fallback webmail for custom corporate domain when native fails',
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
                      nativeLauncher: (_) async => false,
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
                      nativeLauncher: (_) async => false,
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
