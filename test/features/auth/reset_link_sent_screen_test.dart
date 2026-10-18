import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/auth/token_storage.dart';
import 'package:ittalent_mobile/config/routes.dart';
import 'package:ittalent_mobile/features/auth/forgot_password/reset_link_sent_screen.dart';
import 'package:ittalent_mobile/features/auth/widgets/auth_email_hero.dart';
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
  Exception? postError;
  Map<String, dynamic>? lastPostData;
  String? lastPostPath;

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPostPath = path;
    lastPostData = data as Map<String, dynamic>?;

    if (postError != null) {
      throw postError!;
    }

    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: postResponse as T,
      statusCode: 200,
    );
  }
}

void main() {
  Widget buildTestableScreen({
    String? email,
    VoidCallback? onOpenEmailApp,
    int initialCooldownSeconds = 60,
    ApiClient? apiClient,
  }) {
    final router = GoRouter(
      initialLocation: AppRoutes.resetLinkSent,
      routes: [
        GoRoute(
          path: AppRoutes.resetLinkSent,
          builder: (context, state) => ResetLinkSentScreen(
            email: email,
            onOpenEmailApp: onOpenEmailApp,
            initialCooldownSeconds: initialCooldownSeconds,
          ),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) =>
              const Scaffold(body: Text('Forgot Password Screen')),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) =>
              const Scaffold(body: Text('Login Screen')),
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

  testWidgets('ResetLinkSentScreen renders all UI elements and email', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestableScreen(
        email: 'user@example.com',
        initialCooldownSeconds: 60,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthEmailHero), findsOneWidget);
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining('user@example.com'), findsOneWidget);
    expect(find.text('Open email app'), findsOneWidget);
    expect(find.text('Resend link in 1:00'), findsOneWidget);
    expect(find.text('Back to sign in'), findsOneWidget);
  });

  testWidgets('tapping Open email app fires callback', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bool opened = false;
    await tester.pumpWidget(
      buildTestableScreen(
        email: 'user@example.com',
        onOpenEmailApp: () => opened = true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open email app'));
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('resend button triggers forgotPassword when cooldown reaches 0', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeApiClient = FakeApiClient()
      ..postResponse = {'success': true, 'message': 'Resent'};

    await tester.pumpWidget(
      buildTestableScreen(
        email: 'user@example.com',
        initialCooldownSeconds: 0,
        apiClient: fakeApiClient,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resend link'), findsOneWidget);

    await tester.tap(find.text('Resend link'));
    await tester.pumpAndSettle();

    expect(fakeApiClient.lastPostPath, '/api/v1/auth/forgot-password');
    expect(fakeApiClient.lastPostData, {'email': 'user@example.com'});
  });

  testWidgets('Back to sign in navigates to login screen', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back to sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Login Screen'), findsOneWidget);
  });
}
