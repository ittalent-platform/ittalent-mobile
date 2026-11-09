import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/auth/token_storage.dart';
import 'package:ittalent_mobile/components/ui/app_checkbox.dart';
import 'package:ittalent_mobile/config/routes.dart';
import 'package:ittalent_mobile/features/auth/register/register_screen.dart';
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
    ApiClient? apiClient,
    List<RouteBase>? routes,
    String initialLocation = AppRoutes.register,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes:
          routes ??
          [
            GoRoute(
              path: AppRoutes.register,
              builder: (context, state) => const RegisterScreen(),
            ),
            GoRoute(
              path: AppRoutes.verifyEmailNotice,
              builder: (context, state) =>
                  const Scaffold(body: Text('Verify Email Notice Screen')),
            ),
            GoRoute(
              path: AppRoutes.login,
              builder: (context, state) =>
                  const Scaffold(body: Text('Login Screen')),
            ),
            GoRoute(
              path: AppRoutes.welcome,
              builder: (context, state) =>
                  const Scaffold(body: Text('Welcome Screen')),
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

  setUp(() {});

  testWidgets(
    'RegisterScreen renders title, subtitle, form inputs, and actions',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      expect(find.text('Create your account'), findsOneWidget);
      expect(
        find.text(
          'Sign up as a candidate. We’ll email you a link to verify your address.',
        ),
        findsOneWidget,
      );
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);
      expect(find.byType(AppCheckbox), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.textContaining('Already have an account?'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    },
  );

  testWidgets(
    'RegisterScreen validates required fields and terms on empty submit',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Full name is required'), findsOneWidget);
      expect(
        find.text('Username must be at least 3 characters'),
        findsOneWidget,
      );
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
      expect(
        find.text('You must agree to the Terms and Privacy'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'RegisterScreen validates username length and character constraints',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);

      // Min length violation
      await tester.enterText(textFields.at(1), 'ab');
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(
        find.text('Username must be at least 3 characters'),
        findsOneWidget,
      );

      // Max length violation (> 30 characters)
      await tester.enterText(
        textFields.at(1),
        'this_username_is_way_too_long_and_exceeds_thirty_chars',
      );
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.text('Username cannot exceed 30 characters'), findsOneWidget);

      // Invalid character violation (hyphen)
      await tester.enterText(textFields.at(1), 'alex-dev');
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Username may only contain letters, numbers, and underscores',
        ),
        findsOneWidget,
      );

      // Invalid character violation (special character @)
      await tester.enterText(textFields.at(1), 'alex@dev');
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Username may only contain letters, numbers, and underscores',
        ),
        findsOneWidget,
      );

      // Valid username clears error on change
      await tester.enterText(textFields.at(1), 'alex_dev');
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Username may only contain letters, numbers, and underscores',
        ),
        findsNothing,
      );
    },
  );

  testWidgets('RegisterScreen validates password complexity and matching', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();

    // Fill valid name, username, email
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'Nguyễn Văn An');
    await tester.enterText(textFields.at(1), 'alex_dev');
    await tester.enterText(textFields.at(2), 'an.nguyen@example.com');

    // Fill simple password
    await tester.enterText(textFields.at(4), 'short');
    await tester.enterText(textFields.at(5), 'short');
    await tester.tap(find.byType(AppCheckbox));

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Password must be 8–64 characters'), findsOneWidget);

    // Mismatched password
    await tester.enterText(textFields.at(4), 'Password123!');
    await tester.enterText(textFields.at(5), 'DifferentPass123!');

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('RegisterScreen navigates to Login when Sign in is tapped', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Login Screen'), findsOneWidget);
  });

  testWidgets(
    'RegisterScreen navigates to verifyEmailNotice on successful submission without auto-login',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeApiClient = FakeApiClient()
        ..postResponse = {
          'user': {
            'id': 'usr-new',
            'email': 'an.nguyen@example.com',
            'username': 'an_nguyen',
            'role': 'candidate',
            'emailVerified': false,
          },
          'tokens': {
            'accessToken': 'reg-access-jwt',
            'refreshToken': 'reg-refresh-jwt',
          },
          'verificationEmailSent': true,
        };

      await tester.pumpWidget(buildTestableScreen(apiClient: fakeApiClient));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Nguyễn Văn An');
      await tester.enterText(textFields.at(1), 'an_nguyen');
      await tester.enterText(textFields.at(2), 'an.nguyen@example.com');
      await tester.enterText(textFields.at(4), 'Password123!');
      await tester.enterText(textFields.at(5), 'Password123!');
      await tester.tap(find.byType(AppCheckbox));

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(fakeApiClient.lastPostPath, '/api/v1/auth/register');
      expect(fakeApiClient.lastPostData['username'], 'an_nguyen');
      expect(fakeApiClient.lastPostData['email'], 'an.nguyen@example.com');
      expect(find.text('Verify Email Notice Screen'), findsOneWidget);
    },
  );
}
