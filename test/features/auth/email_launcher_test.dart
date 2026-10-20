import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/auth/utils/email_launcher.dart';
import 'package:open_mail_app/open_mail_app.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  group('launchEmailApp Tests', () {
    testWidgets('launches native email app inbox when open_mail_app succeeds', (
      WidgetTester tester,
    ) async {
      bool mailAppOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => launchEmailApp(
                    context,
                    email: 'candidate@company.com',
                    mailAppOpener: ({nativePickerTitle}) async {
                      mailAppOpened = true;
                      return OpenMailAppResult(didOpen: true);
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

      expect(mailAppOpened, isTrue);
    });

    testWidgets(
      'displays picker dialog when multiple mail apps are available',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => launchEmailApp(
                      context,
                      email: 'candidate@company.com',
                      mailAppOpener: ({nativePickerTitle}) async {
                        return OpenMailAppResult(
                          didOpen: false,
                          options: const [
                            MailApp(
                              name: 'Gmail',
                              iosLaunchScheme: 'googlegmail://',
                            ),
                            MailApp(
                              name: 'Outlook',
                              iosLaunchScheme: 'ms-outlook://',
                            ),
                          ],
                        );
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

        expect(find.byType(MailAppPickerDialog), findsOneWidget);
      },
    );

    testWidgets(
      'falls back to Gmail web inbox when native mail fails for @gmail.com',
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
                      mailAppOpener: ({nativePickerTitle}) async {
                        return OpenMailAppResult(didOpen: false);
                      },
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
      'falls back to Outlook web inbox when native mail fails for @outlook.com',
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
                      mailAppOpener: ({nativePickerTitle}) async {
                        return OpenMailAppResult(didOpen: false);
                      },
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
                      mailAppOpener: ({nativePickerTitle}) async {
                        return OpenMailAppResult(didOpen: false);
                      },
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
