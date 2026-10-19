import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/app/router.dart';
import 'package:ittalent_mobile/auth/auth_notifier.dart';
import 'package:ittalent_mobile/auth/auth_state.dart';
import 'package:ittalent_mobile/auth/token_storage.dart';
import 'package:ittalent_mobile/features/auth/reset_password/reset_password_screen.dart';
import 'package:ittalent_mobile/features/auth/verify_email/verify_email_screen.dart';
import 'package:ittalent_mobile/features/auth/login/login_screen.dart';
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

class FakeTestAuthNotifier extends AuthNotifier {
  FakeTestAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  AuthState build() => _initialState;
}

void main() {
  group('Deep Linking & App Links Route Matching', () {
    testWidgets(
      'matches /verify-email with query parameters and displays VerifyEmailScreen',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer(
          overrides: [
            tokenStorageProvider.overrideWithValue(MockTokenStorage()),
            authNotifierProvider.overrideWith(
              () => FakeTestAuthNotifier(AuthState.unauthenticated()),
            ),
          ],
        );
        addTearDown(container.dispose);

        final router = container.read(routerProvider);
        router.go(
          '/verify-email?token=abc-123-xyz&email=candidate@example.com',
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(VerifyEmailScreen), findsOneWidget);
        expect(find.text('Verify your email'), findsOneWidget);
        expect(find.text('Verify email'), findsOneWidget);
      },
    );

    testWidgets(
      'matches /reset-password with token parameter and displays ResetPasswordScreen',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer(
          overrides: [
            tokenStorageProvider.overrideWithValue(MockTokenStorage()),
            authNotifierProvider.overrideWith(
              () => FakeTestAuthNotifier(AuthState.unauthenticated()),
            ),
          ],
        );
        addTearDown(container.dispose);

        final router = container.read(routerProvider);
        router.go('/reset-password?token=dev-mock-valid');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ResetPasswordScreen), findsOneWidget);
        expect(find.text('Set a new password'), findsOneWidget);
      },
    );

    testWidgets(
      'routes /login for custom scheme handoff and displays LoginScreen',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final container = ProviderContainer(
          overrides: [
            tokenStorageProvider.overrideWithValue(MockTokenStorage()),
            authNotifierProvider.overrideWith(
              () => FakeTestAuthNotifier(AuthState.unauthenticated()),
            ),
          ],
        );
        addTearDown(container.dispose);

        final router = container.read(routerProvider);
        router.go('/login');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );
  });
}
