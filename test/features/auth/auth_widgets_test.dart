import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/auth/widgets/auth_brand_header.dart';
import 'package:ittalent_mobile/features/auth/widgets/auth_divider.dart';
import 'package:ittalent_mobile/features/auth/widgets/auth_error_banner.dart';
import 'package:ittalent_mobile/features/auth/widgets/auth_footer_note.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  group('AuthBrandHeader Tests', () {
    testWidgets('renders title, subtitle, and logo', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AuthBrandHeader(
            title: 'Welcome back',
            subtitle: 'Sign in to your candidate account.',
          ),
        ),
      );

      expect(find.text('ITTALENT'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in to your candidate account.'), findsOneWidget);
    });

    testWidgets('renders back button and triggers callback when provided', (
      WidgetTester tester,
    ) async {
      bool backTapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          AuthBrandHeader(
            title: 'Forgot password',
            onBack: () => backTapped = true,
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      await tester.tap(find.byType(IconButton));
      expect(backTapped, isTrue);
    });
  });

  group('AuthErrorBanner Tests', () {
    testWidgets('renders error banner with message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AuthErrorBanner(
            message: 'Email or password is incorrect.',
            tone: AuthBannerTone.error,
          ),
        ),
      );

      expect(find.text('Email or password is incorrect.'), findsOneWidget);
    });

    testWidgets(
      'renders warning banner with action link and triggers callback',
      (WidgetTester tester) async {
        bool actionTapped = false;
        await tester.pumpWidget(
          buildTestableWidget(
            AuthErrorBanner(
              message: 'Verify your email before signing in.',
              tone: AuthBannerTone.warning,
              actionLabel: 'Resend link',
              onAction: () => actionTapped = true,
            ),
          ),
        );

        expect(
          find.text('Verify your email before signing in.'),
          findsOneWidget,
        );
        expect(find.text('Resend link'), findsOneWidget);

        await tester.tap(find.text('Resend link'));
        expect(actionTapped, isTrue);
      },
    );
  });

  group('AuthDivider Tests', () {
    testWidgets('renders divider text', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const AuthDivider(text: 'New to ITTalent?')),
      );

      expect(find.text('New to ITTalent?'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });

  group('AuthFooterNote Tests', () {
    testWidgets('renders employer footer note and handles tap', (
      WidgetTester tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          AuthFooterNote(onTapEmployerLink: () => tapped = true),
        ),
      );

      expect(find.byType(AuthFooterNote), findsOneWidget);
      await tester.tap(find.byType(AuthFooterNote));
      expect(tapped, isTrue);
    });
  });
}
