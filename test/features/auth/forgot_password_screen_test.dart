import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ittalent_mobile/api/api_error.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/auth/token_storage.dart';
import 'package:ittalent_mobile/config/routes.dart';
import 'package:ittalent_mobile/features/auth/forgot_password/forgot_password_screen.dart';
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
    ApiClient? apiClient,
    List<RouteBase>? routes,
    String initialLocation = AppRoutes.forgotPassword,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes:
          routes ??
          [
            GoRoute(
              path: AppRoutes.forgotPassword,
              builder: (context, state) => const ForgotPasswordScreen(),
            ),
            GoRoute(
              path: AppRoutes.resetLinkSent,
              builder: (context, state) {
                final email = state.uri.queryParameters['email'];
                return Scaffold(body: Text('Reset Link Sent Screen: $email'));
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

  testWidgets('ForgotPasswordScreen renders all required UI elements', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();

    expect(find.text('Forgot password?'), findsOneWidget);
    expect(
      find.text(
        'Enter the email you signed up with. We’ll send a link to set a new password.',
      ),
      findsOneWidget,
    );
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Send reset link'), findsOneWidget);
    expect(find.text('Back to sign in'), findsOneWidget);
  });

  testWidgets('shows validation error when email is empty', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
  });

  testWidgets('shows validation error when email format is invalid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'invalid-email');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address'), findsOneWidget);
  });

  testWidgets('submits request and navigates to resetLinkSent on success', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeApiClient = FakeApiClient()
      ..postResponse = {'success': true, 'message': 'Reset link sent'};

    await tester.pumpWidget(buildTestableScreen(apiClient: fakeApiClient));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'candidate@example.com');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(fakeApiClient.lastPostPath, '/api/v1/auth/forgot-password');
    expect(fakeApiClient.lastPostData, {'email': 'candidate@example.com'});
    expect(
      find.text('Reset Link Sent Screen: candidate@example.com'),
      findsOneWidget,
    );
  });

  testWidgets('displays error banner when API returns error', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeApiClient = FakeApiClient()
      ..postError = const ApiError(message: 'Rate limit exceeded');

    await tester.pumpWidget(buildTestableScreen(apiClient: fakeApiClient));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'candidate@example.com');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(find.text('Rate limit exceeded'), findsOneWidget);
  });

  testWidgets('Back to sign in navigates to login route', (tester) async {
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
