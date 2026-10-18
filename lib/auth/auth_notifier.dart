import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_error.dart';
import '../api/client.dart';
import 'auth_dto.dart';
import 'auth_state.dart';
import 'token_storage.dart';

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(() => checkAuthStatus());
    return AuthState.initial();
  }

  TokenStorage get _tokenStorage => ref.read(tokenStorageProvider);
  ApiClient get _apiClient => ref.read(apiClientProvider);

  Future<void> checkAuthStatus() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      state = AuthState.unauthenticated();
      return;
    }

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/auth/me',
      );
      final data = response.data;
      if (data != null) {
        state = AuthState.authenticated(user: UserDTO.fromJson(data));
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> login(String identifier, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/auth/login',
        data: {'identifier': identifier.trim(), 'password': password},
      );

      final data = response.data;
      final tokens = data?['tokens'] as Map<String, dynamic>?;
      final accessToken =
          tokens?['accessToken']?.toString() ??
          data?['accessToken']?.toString();
      final refreshToken =
          tokens?['refreshToken']?.toString() ??
          data?['refreshToken']?.toString();

      if (accessToken != null && accessToken.isNotEmpty) {
        await _tokenStorage.saveAccessToken(accessToken);
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await _tokenStorage.saveRefreshToken(refreshToken);
        }

        final userMap = data?['user'] as Map<String, dynamic>?;
        var user = userMap != null
            ? UserDTO.fromJson(userMap)
            : UserDTO(
                id: '',
                email: identifier.contains('@') ? identifier.trim() : '',
                username: identifier.contains('@') ? '' : identifier.trim(),
                role: 'candidate',
              );
        if (user.email.isEmpty && identifier.contains('@')) {
          user = user.copyWith(email: identifier.trim());
        }
        state = AuthState.authenticated(user: user);
        return true;
      } else {
        state = AuthState.unauthenticated('Invalid credentials');
        return false;
      }
    } on ApiError catch (e) {
      state = AuthState.unauthenticated(e.message);
      return false;
    } catch (e) {
      state = AuthState.unauthenticated(e.toString());
      return false;
    }
  }

  Future<bool> register(RegisterRequest request) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/auth/register',
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null) {
        state = AuthState.unauthenticated('Registration failed');
        return false;
      }

      final res = RegisterResponse.fromJson(data);
      if (res.tokens.accessToken.isNotEmpty) {
        await _tokenStorage.saveAccessToken(res.tokens.accessToken);
        if (res.tokens.refreshToken.isNotEmpty) {
          await _tokenStorage.saveRefreshToken(res.tokens.refreshToken);
        }
      }

      state = AuthState.authenticated(user: res.user);
      return true;
    } on ApiError catch (e) {
      state = AuthState.unauthenticated(e.message);
      return false;
    } catch (e) {
      state = AuthState.unauthenticated(e.toString());
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/auth/forgot-password',
        data: ForgotPasswordRequest(email: email).toJson(),
      );
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return true;
    } on ApiError catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<ResetPasswordTokenResponse> validateResetToken(String token) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/auth/reset-password',
        queryParameters: {'token': token},
      );
      return ResetPasswordTokenResponse.fromJson(response.data ?? {});
    } on ApiError catch (e) {
      return ResetPasswordTokenResponse(
        success: false,
        valid: false,
        message: e.message,
      );
    } catch (e) {
      return ResetPasswordTokenResponse(
        success: false,
        valid: false,
        message: e.toString(),
      );
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/auth/reset-password',
        data: ResetPasswordRequest(
          token: token,
          newPassword: newPassword,
        ).toJson(),
      );
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return true;
    } on ApiError catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> resendVerificationEmail(String email) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/auth/resend-verification-email',
        data: ResendVerificationEmailRequest(email: email).toJson(),
      );
      return true;
    } on ApiError catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> verifyEmail(String token) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _apiClient.get<dynamic>(
        '/api/v1/auth/verify-email',
        queryParameters: {'token': token},
      );
      await checkAuthStatus();
      return true;
    } on ApiError catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    state = AuthState.unauthenticated();
  }
}
