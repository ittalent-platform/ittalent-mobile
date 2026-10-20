import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/api_error.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/auth/auth_dto.dart';
import 'package:ittalent_mobile/auth/auth_notifier.dart';
import 'package:ittalent_mobile/auth/auth_state.dart';
import 'package:ittalent_mobile/auth/token_storage.dart';

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage({String? initialAccessToken, String? initialRefreshToken})
    : accessToken = initialAccessToken,
      refreshToken = initialRefreshToken;

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
  dynamic getResponse;
  Exception? postError;
  Exception? getError;

  Map<String, dynamic>? lastPostData;
  String? lastPostPath;
  String? lastGetPath;

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
    lastGetPath = path;

    if (getError != null) {
      throw getError!;
    }

    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: getResponse as T,
      statusCode: 200,
    );
  }
}

void main() {
  group('AuthNotifier Tests', () {
    late FakeTokenStorage fakeTokenStorage;
    late FakeApiClient fakeApiClient;
    late ProviderContainer container;

    setUp(() {
      fakeTokenStorage = FakeTokenStorage();
      fakeApiClient = FakeApiClient();
      container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(fakeTokenStorage),
          apiClientProvider.overrideWithValue(fakeApiClient),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is AuthStatus.initial', () {
      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.initial);
    });

    test(
      'checkAuthStatus sets unauthenticated when token is missing',
      () async {
        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.checkAuthStatus();

        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.unauthenticated);
        expect(state.isAuthenticated, isFalse);
      },
    );

    test(
      'checkAuthStatus sets authenticated when token is valid and /me succeeds',
      () async {
        fakeTokenStorage.accessToken = 'valid-token';
        fakeApiClient.getResponse = {
          'id': 'usr-123',
          'email': 'alex@example.com',
          'role': 'candidate',
        };

        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.checkAuthStatus();

        expect(fakeApiClient.lastGetPath, '/api/v1/auth/me');
        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.authenticated);
        expect(state.userId, 'usr-123');
        expect(state.email, 'alex@example.com');
        expect(state.role, 'candidate');
        expect(state.isAuthenticated, isTrue);
      },
    );

    test('login sends identifier and parses nested tokens correctly', () async {
      fakeApiClient.postResponse = {
        'user': {
          'id': 'usr-456',
          'email': 'alex_dev@test.com',
          'role': 'candidate',
        },
        'tokens': {
          'accessToken': 'jwt-access-token-abc',
          'refreshToken': 'jwt-refresh-token-xyz',
        },
      };

      final notifier = container.read(authNotifierProvider.notifier);
      final result = await notifier.login('alex_dev', 'SecretPass123!');

      expect(result, isTrue);
      expect(fakeApiClient.lastPostPath, '/api/v1/auth/login');
      expect(fakeApiClient.lastPostData, {
        'identifier': 'alex_dev',
        'password': 'SecretPass123!',
      });

      expect(fakeTokenStorage.accessToken, 'jwt-access-token-abc');
      expect(fakeTokenStorage.refreshToken, 'jwt-refresh-token-xyz');

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.userId, 'usr-456');
      expect(state.email, 'alex_dev@test.com');
      expect(state.errorMessage, isNull);
    });

    test(
      'login with email identifier sets email fallback when user email omitted',
      () async {
        fakeApiClient.postResponse = {
          'user': {'id': 'usr-789', 'role': 'candidate'},
          'tokens': {
            'accessToken': 'jwt-token-123',
            'refreshToken': 'jwt-refresh-456',
          },
        };

        final notifier = container.read(authNotifierProvider.notifier);
        final result = await notifier.login(
          'developer@example.com',
          'Password123!',
        );

        expect(result, isTrue);
        final state = container.read(authNotifierProvider);
        expect(state.email, 'developer@example.com');
      },
    );

    test('login captures ApiError message when credentials invalid', () async {
      fakeApiClient.postError = const ApiError(
        message: 'Email or password is incorrect.',
        statusCode: 401,
      );

      final notifier = container.read(authNotifierProvider.notifier);
      final result = await notifier.login('wrong_user', 'bad_pass');

      expect(result, isFalse);
      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.errorMessage, 'Email or password is incorrect.');
      expect(state.isAuthenticated, isFalse);
    });

    test('login fails when tokens object is missing or empty', () async {
      fakeApiClient.postResponse = {
        'user': {'id': 'usr-123'},
      };

      final notifier = container.read(authNotifierProvider.notifier);
      final result = await notifier.login('test_user', 'pass');

      expect(result, isFalse);
      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.errorMessage, 'Invalid credentials');
    });

    test(
      'register sends payload and keeps unauthenticated state on success',
      () async {
        fakeApiClient.postResponse = {
          'user': {
            'id': 'usr-new',
            'email': 'new_dev@example.com',
            'username': 'new_dev',
            'role': 'candidate',
            'emailVerified': false,
          },
          'tokens': {
            'accessToken': 'reg-access-jwt',
            'refreshToken': 'reg-refresh-jwt',
          },
          'verificationEmailSent': true,
        };

        final notifier = container.read(authNotifierProvider.notifier);
        final result = await notifier.register(
          const RegisterRequest(
            email: 'new_dev@example.com',
            username: 'new_dev',
            password: 'Password123!',
          ),
        );

        expect(result, isTrue);
        expect(fakeApiClient.lastPostPath, '/api/v1/auth/register');
        // Tokens must NOT be stored upon registration; user is not logged in immediately
        expect(fakeTokenStorage.accessToken, isNull);
        expect(fakeTokenStorage.refreshToken, isNull);

        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.unauthenticated);
        expect(state.userId, 'usr-new');
        expect(state.isEmailVerified, isFalse);
      },
    );

    test('forgotPassword sends email payload and handles ApiError', () async {
      fakeApiClient.postResponse = {'success': true, 'message': 'Email sent'};

      final notifier = container.read(authNotifierProvider.notifier);
      final result = await notifier.forgotPassword('alex@example.com');

      expect(result, isTrue);
      expect(fakeApiClient.lastPostPath, '/api/v1/auth/forgot-password');
      expect(fakeApiClient.lastPostData, {'email': 'alex@example.com'});

      fakeApiClient.postError = const ApiError(
        message: 'Too many requests',
        statusCode: 429,
      );
      final errorResult = await notifier.forgotPassword('alex@example.com');
      expect(errorResult, isFalse);
      expect(
        container.read(authNotifierProvider).errorMessage,
        'Too many requests',
      );
    });

    test('validateResetToken returns token validity', () async {
      fakeApiClient.getResponse = {
        'success': true,
        'data': {'valid': true},
      };

      final notifier = container.read(authNotifierProvider.notifier);
      final res = await notifier.validateResetToken('token-abc');

      expect(fakeApiClient.lastGetPath, '/api/v1/auth/reset-password');
      expect(res.valid, isTrue);
      expect(res.success, isTrue);
    });

    test('resetPassword sends new password and token', () async {
      fakeApiClient.postResponse = {'success': true};

      final notifier = container.read(authNotifierProvider.notifier);
      final result = await notifier.resetPassword(
        'token-abc',
        'BrandNewPassword123!',
      );

      expect(result, isTrue);
      expect(fakeApiClient.lastPostPath, '/api/v1/auth/reset-password');
      expect(fakeApiClient.lastPostData, {
        'token': 'token-abc',
        'newPassword': 'BrandNewPassword123!',
      });
    });

    test('resendVerificationEmail calls endpoint with email', () async {
      fakeApiClient.postResponse = {'success': true};

      final notifier = container.read(authNotifierProvider.notifier);
      final result = await notifier.resendVerificationEmail('dev@example.com');

      expect(result, isTrue);
      expect(
        fakeApiClient.lastPostPath,
        '/api/v1/auth/resend-verification-email',
      );
      expect(fakeApiClient.lastPostData, {'email': 'dev@example.com'});
    });

    test(
      'verifyEmail calls endpoint with token and checks auth status',
      () async {
        fakeApiClient.getResponse = {'success': true};

        final notifier = container.read(authNotifierProvider.notifier);
        final result = await notifier.verifyEmail('verify-token-123');

        expect(result, isTrue);
        expect(fakeApiClient.lastGetPath, '/api/v1/auth/verify-email');
      },
    );

    test('logout clears tokens and sets unauthenticated state', () async {
      fakeTokenStorage.accessToken = 'jwt-token';
      fakeTokenStorage.refreshToken = 'jwt-refresh';

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.logout();

      expect(fakeTokenStorage.accessToken, isNull);
      expect(fakeTokenStorage.refreshToken, isNull);

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.unauthenticated);
    });
  });
}
