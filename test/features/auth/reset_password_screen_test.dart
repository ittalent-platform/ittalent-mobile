import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ittalent_mobile/api/api_error.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/auth/token_storage.dart';
import 'package:ittalent_mobile/components/ui/app_button.dart';
import 'package:ittalent_mobile/config/routes.dart';
import 'package:ittalent_mobile/features/auth/reset_password/reset_password_screen.dart';
import 'package:ittalent_mobile/features/auth/widgets/password_criteria_chips.dart';
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

  dynamic getResponse;
  Exception? getError;
  String? lastGetPath;
  Map<String, dynamic>? lastGetParams;

  dynamic postResponse;
  Exception? postError;
  String? lastPostPath;
  Map<String, dynamic>? lastPostData;

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
      statusCode: 200,
    );
  }

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
    required String token,
    String? email,
    bool skipTokenValidationForTesting = false,
    ApiClient? apiClient,
  }) {
    final router = GoRouter(
      initialLocation: AppRoutes.resetPassword,
      routes: [
        GoRoute(
          path: AppRoutes.resetPassword,
          builder: (context, state) => ResetPasswordScreen(
            token: token,
            email: email,
            skipTokenValidationForTesting: skipTokenValidationForTesting,
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

  testWidgets('renders invalid link view when token is empty', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestableScreen(token: ''));
    await tester.pumpAndSettle();

    expect(find.text('Invalid link'), findsOneWidget);
    expect(find.text('This link isn’t valid'), findsOneWidget);
    expect(find.text('Request a new link'), findsOneWidget);

    await tester.tap(find.text('Request a new link'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot Password Screen'), findsOneWidget);
  });

  testWidgets(
    'renders invalid link view when token preflight validation fails',
    (tester) async {
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
        buildTestableScreen(token: 'expired_token', apiClient: fakeApiClient),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invalid link'), findsOneWidget);
      expect(
        find.text('This verification link is no longer valid.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('renders form and criteria when token is valid', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeApiClient = FakeApiClient()
      ..getResponse = {
        'success': true,
        'data': {'valid': true},
      };

    await tester.pumpWidget(
      buildTestableScreen(
        token: 'valid_token_123',
        email: 'an.nguyen@gmail.com',
        apiClient: fakeApiClient,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set a new password'), findsOneWidget);
    expect(
      find.text('For an.nguyen@gmail.com. You’ll sign in with it next time.'),
      findsOneWidget,
    );
    expect(find.text('New password'), findsOneWidget);
    expect(find.text('Confirm new password'), findsOneWidget);
    expect(find.byType(PasswordCriteriaChips), findsOneWidget);
    expect(find.text('Save new password'), findsOneWidget);
  });

  testWidgets(
    'enables Save button only when all criteria are met and passwords match',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableScreen(
          token: 'valid_token',
          skipTokenValidationForTesting: true,
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      // Initially disabled
      final buttonFinder = find.widgetWithText(AppButton, 'Save new password');
      AppButton button = tester.widget(buttonFinder);
      expect(button.onPressed, isNull);

      // Enter partial password (missing special char)
      await tester.enterText(textFields.first, 'Hello2026');
      await tester.pumpAndSettle();
      button = tester.widget(buttonFinder);
      expect(button.onPressed, isNull);

      // Enter full valid password
      await tester.enterText(textFields.first, 'Hello2026!');
      await tester.pumpAndSettle();
      button = tester.widget(buttonFinder);
      expect(button.onPressed, isNull); // confirm pass still empty

      // Enter matching confirm password
      await tester.enterText(textFields.last, 'Hello2026!');
      await tester.pumpAndSettle();
      button = tester.widget(buttonFinder);
      expect(button.onPressed, isNotNull); // enabled!
    },
  );

  testWidgets('submits reset and shows success screen', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeApiClient = FakeApiClient()
      ..postResponse = {'success': true, 'message': 'Password updated'};

    await tester.pumpWidget(
      buildTestableScreen(
        token: 'token_xyz',
        skipTokenValidationForTesting: true,
        apiClient: fakeApiClient,
      ),
    );
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.first, 'NewStrongPass1!');
    await tester.enterText(textFields.last, 'NewStrongPass1!');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save new password'));
    await tester.pumpAndSettle();

    expect(fakeApiClient.lastPostPath, '/api/v1/auth/reset-password');
    expect(fakeApiClient.lastPostData, {
      'token': 'token_xyz',
      'newPassword': 'NewStrongPass1!',
    });

    // Check success screen
    expect(find.text('Password changed'), findsOneWidget);
    expect(
      find.text('Password changed. Sign in with your new password.'),
      findsOneWidget,
    );

    // Click Sign in
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Login Screen'), findsOneWidget);
  });
}
