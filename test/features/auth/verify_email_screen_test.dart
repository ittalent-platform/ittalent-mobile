import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ittalent_mobile/api/api_error.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/auth/token_storage.dart';
import 'package:ittalent_mobile/config/routes.dart';
import 'package:ittalent_mobile/features/auth/verify_email/verify_email_screen.dart';
import 'package:ittalent_mobile/features/auth/widgets/auth_email_hero.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

  dynamic getResponse;
  int getStatusCode = 200;
  Map<String, List<String>> getHeaders = {};
  Exception? getError;
  String? lastGetPath;
  Map<String, dynamic>? lastGetParams;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastGetPath = path;
    lastGetParams = queryParameters;

    if (getError != null) {
      throw getError!;
    }

    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: getResponse as T,
      statusCode: getStatusCode,
      headers: Headers.fromMap(getHeaders),
    );
  }
}

void main() {
  Widget buildTestableScreen({
    String? token,
    String? email,
    bool initialVerified = false,
    ApiClient? apiClient,
  }) {
    final router = GoRouter(
      initialLocation: AppRoutes.verifyEmail,
      routes: [
        GoRoute(
          path: AppRoutes.verifyEmail,
          builder: (context, state) => VerifyEmailScreen(
            token: token,
            email: email,
            initialVerified: initialVerified,
          ),
        ),
        GoRoute(
          path: AppRoutes.verifyEmailNotice,
          builder: (context, state) {
            final e = state.uri.queryParameters['email'];
            return Scaffold(body: Text('Verify Email Notice Screen: $e'));
          },
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

  testWidgets('VerifyEmailScreen renders unverified confirmation state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestableScreen(token: 'token123', email: 'candidate@example.com'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthEmailHero), findsOneWidget);
    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.textContaining('candidate@example.com'), findsOneWidget);
    expect(
      find.textContaining('Opening the link alone doesn’t verify it.'),
      findsOneWidget,
    );
    expect(find.byIcon(LucideIcons.shield), findsOneWidget);
    expect(find.text('Verify email'), findsOneWidget);
  });

  testWidgets('shows error state when token is empty on verification tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestableScreen(token: '', email: 'candidate@example.com'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verify email'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid or expired link'), findsOneWidget);
    expect(
      find.text('This verification link is no longer valid.'),
      findsOneWidget,
    );
    expect(find.text('Resend link'), findsOneWidget);
  });

  testWidgets(
    'calls verifyEmail API and transitions to Email verified on success',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeApiClient = FakeApiClient()..getResponse = {'success': true};

      await tester.pumpWidget(
        buildTestableScreen(
          token: 'valid_verify_token',
          email: 'candidate@example.com',
          apiClient: fakeApiClient,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Verify email'));
      await tester.pumpAndSettle();

      expect(fakeApiClient.lastGetPath, '/api/v1/auth/verify-email');
      expect(fakeApiClient.lastGetParams, {'token': 'valid_verify_token'});

      expect(find.text('Email verified'), findsOneWidget);
      expect(
        find.text('Your account is ready. Sign in to start applying.'),
        findsOneWidget,
      );
      expect(find.text('Sign in'), findsOneWidget);

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Login Screen'), findsOneWidget);
    },
  );

  testWidgets('displays error state when verifyEmail API fails', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeApiClient = FakeApiClient()
      ..getError = const ApiError(
        message: 'This verification link is no longer valid.',
      );

    await tester.pumpWidget(
      buildTestableScreen(
        token: 'expired_verify_token',
        email: 'candidate@example.com',
        apiClient: fakeApiClient,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verify email'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid or expired link'), findsOneWidget);
    expect(
      find.text('This verification link is no longer valid.'),
      findsOneWidget,
    );
    expect(find.text('Resend link'), findsOneWidget);

    await tester.tap(find.text('Resend link'));
    await tester.pumpAndSettle();

    expect(
      find.text('Verify Email Notice Screen: candidate@example.com'),
      findsOneWidget,
    );
  });

  testWidgets('renders Email verified directly when initialVerified is true', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableScreen(initialVerified: true));
    await tester.pumpAndSettle();

    expect(find.text('Email verified'), findsOneWidget);
    expect(
      find.text('Your account is ready. Sign in to start applying.'),
      findsOneWidget,
    );
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets(
    'handles 302 redirect to stage=success and transitions to Email verified',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeApiClient = FakeApiClient()
        ..getStatusCode = 302
        ..getHeaders = {
          'location': ['http://localhost:5173/verify-email?stage=success'],
        };

      await tester.pumpWidget(
        buildTestableScreen(
          token: 'token_302_success',
          email: 'candidate@example.com',
          apiClient: fakeApiClient,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Verify email'));
      await tester.pumpAndSettle();

      expect(find.text('Email verified'), findsOneWidget);
      expect(
        find.text('Your account is ready. Sign in to start applying.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'handles 302 redirect to stage=already-verified and transitions to Email verified',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeApiClient = FakeApiClient()
        ..getStatusCode = 302
        ..getHeaders = {
          'location': [
            'http://localhost:5173/verify-email?stage=already-verified',
          ],
        };

      await tester.pumpWidget(
        buildTestableScreen(
          token: 'token_302_already_verified',
          email: 'candidate@example.com',
          apiClient: fakeApiClient,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Verify email'));
      await tester.pumpAndSettle();

      expect(find.text('Email verified'), findsOneWidget);
    },
  );
}
