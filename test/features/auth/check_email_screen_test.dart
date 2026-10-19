import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ittalent_mobile/api/client.dart';
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

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(dio: Dio());

  dynamic postResponse;
  String? lastPostPath;
  dynamic lastPostData;
  Exception? postError;

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPostPath = path;
    lastPostData = data;

    if (postError != null) {
      throw postError!;
    }

    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: (postResponse ?? {'success': true}) as T,
      statusCode: 200,
    );
  }
}

void main() {
  Widget buildTestableScreen({
    String email = 'an.nguyen@gmail.com',
    VoidCallback? onOpenEmailApp,
    int initialCooldownSeconds = 60,
    ApiClient? apiClient,
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
      overrides: [
        tokenStorageProvider.overrideWithValue(MockTokenStorage()),
        if (apiClient != null) apiClientProvider.overrideWithValue(apiClient),
      ],
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

  testWidgets(
    'CheckEmailScreen triggers resendVerificationEmail and shows SnackBar when resend button is tapped',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeApiClient = FakeApiClient();
      await tester.pumpWidget(
        buildTestableScreen(
          email: 'test.user@company.com',
          initialCooldownSeconds: 0,
          apiClient: fakeApiClient,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resend link'), findsOneWidget);
      await tester.tap(find.text('Resend link'));
      await tester.pumpAndSettle();

      expect(
        fakeApiClient.lastPostPath,
        '/api/v1/auth/resend-verification-email',
      );
      expect(fakeApiClient.lastPostData, {'email': 'test.user@company.com'});
      expect(
        find.text(
          'A verification email has been sent to test.user@company.com',
        ),
        findsOneWidget,
      );
    },
  );
}
