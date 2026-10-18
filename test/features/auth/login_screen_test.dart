import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ittalent_mobile/api/api_error.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/auth/token_storage.dart';
import 'package:ittalent_mobile/config/routes.dart';
import 'package:ittalent_mobile/features/auth/login/login_screen.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<void> saveAccessToken(String token) async {
    accessToken = token;
  }

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveRefreshToken(String token) async {
    refreshToken = token;
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
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

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: null,
      statusCode: 200,
    );
  }
}

void main() {
  late FakeApiClient fakeApiClient;
  late FakeTokenStorage fakeTokenStorage;

  setUp(() {
    fakeApiClient = FakeApiClient();
    fakeTokenStorage = FakeTokenStorage();
  });

  Widget buildTestableWidget({required Widget child}) {
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(fakeApiClient),
        tokenStorageProvider.overrideWithValue(fakeTokenStorage),
      ],
      child: MaterialApp(theme: AppTheme.light, home: child),
    );
  }

  testWidgets('LoginScreen renders header, form inputs, and buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget(child: const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text('Sign in to your ITTalent candidate account.'),
      findsOneWidget,
    );
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('New to ITTalent?'), findsOneWidget);
    expect(find.text('Create a candidate account'), findsOneWidget);
  });

  testWidgets('LoginScreen displays validation errors on empty submission', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget(child: const LoginScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('LoginScreen toggles password obscurity on eye icon tap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget(child: const LoginScreen()));
    await tester.pumpAndSettle();

    final passwordFieldFinder = find.byType(TextField).at(1);
    expect(
      (tester.widget(passwordFieldFinder) as TextField).obscureText,
      isTrue,
    );

    final eyeButton = find.byType(IconButton);
    await tester.tap(eyeButton);
    await tester.pump();

    expect(
      (tester.widget(passwordFieldFinder) as TextField).obscureText,
      isFalse,
    );
  });

  testWidgets(
    'LoginScreen submits credentials and shows error banner on failure',
    (WidgetTester tester) async {
      fakeApiClient.postError = const ApiError(
        message: 'Email or password is incorrect.',
        statusCode: 401,
      );

      await tester.pumpWidget(buildTestableWidget(child: const LoginScreen()));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'user@example.com');
      await tester.enterText(textFields.at(1), 'Secret123!');

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(fakeApiClient.lastPostPath, '/api/v1/auth/login');
      expect(fakeApiClient.lastPostData, {
        'identifier': 'user@example.com',
        'password': 'Secret123!',
      });
      expect(find.text('Email or password is incorrect.'), findsOneWidget);
    },
  );

  testWidgets('LoginScreen navigates to forgot-password and register routes', (
    WidgetTester tester,
  ) async {
    String? currentRoute;

    final router = GoRouter(
      initialLocation: AppRoutes.login,
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) {
            currentRoute = AppRoutes.forgotPassword;
            return const Scaffold(body: Text('Forgot Password Screen'));
          },
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) {
            currentRoute = AppRoutes.register;
            return const Scaffold(body: Text('Register Screen'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(fakeApiClient),
          tokenStorageProvider.overrideWithValue(fakeTokenStorage),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Forgot password?
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(currentRoute, AppRoutes.forgotPassword);

    // Go back and tap Create a candidate account
    router.go(AppRoutes.login);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a candidate account'));
    await tester.pumpAndSettle();
    expect(currentRoute, AppRoutes.register);
  });
}
