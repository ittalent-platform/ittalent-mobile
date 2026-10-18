import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ittalent_mobile/auth/token_storage.dart';
import 'package:ittalent_mobile/config/routes.dart';
import 'package:ittalent_mobile/features/auth/verify_email/check_email_screen.dart';
import 'package:ittalent_mobile/features/auth/widgets/auth_email_hero.dart';
import 'package:ittalent_mobile/features/auth/widgets/cooldown_timer_button.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';

class MockTokenStorage extends TokenStorage {
  @override
  Future<String?> getAccessToken() async => null;
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<void> saveAccessToken(String token) async {}
  @override
  Future<void> saveRefreshToken(String token) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  Widget buildTestableScreen({
    String email = 'an.nguyen@gmail.com',
    VoidCallback? onOpenEmailApp,
    int initialCooldownSeconds = 60,
  }) {
    final router = GoRouter(
      initialLocation: AppRoutes.verifyEmailNotice,
      routes: [
        GoRoute(
          path: AppRoutes.verifyEmailNotice,
          builder: (context, state) => CheckEmailScreen(
            email: email,
            onOpenEmailApp: onOpenEmailApp,
            initialCooldownSeconds: initialCooldownSeconds,
          ),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) =>
              const Scaffold(body: Text('Register Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [tokenStorageProvider.overrideWithValue(MockTokenStorage())],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  testWidgets('CheckEmailScreen renders email hero, actions, and footer', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestableScreen(email: 'test.user@company.com'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthEmailHero), findsOneWidget);
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining('test.user@company.com'), findsOneWidget);
    expect(find.text('Open email app'), findsOneWidget);
    expect(find.byType(CooldownTimerButton), findsOneWidget);
    expect(find.textContaining('Wrong email?'), findsOneWidget);
    expect(find.text('Sign up again'), findsOneWidget);
  });

  testWidgets('CheckEmailScreen triggers onOpenEmailApp callback when tapped', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bool openedEmail = false;
    await tester.pumpWidget(
      buildTestableScreen(onOpenEmailApp: () => openedEmail = true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open email app'));
    await tester.pumpAndSettle();

    expect(openedEmail, isTrue);
  });

  testWidgets(
    'CheckEmailScreen navigates back to Register when Sign up again is tapped',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign up again'));
      await tester.pumpAndSettle();

      expect(find.text('Register Screen'), findsOneWidget);
    },
  );
}
