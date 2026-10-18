import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_error.dart';
import '../api/client.dart';
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
        state = AuthState.authenticated(
          userId: data['id']?.toString() ?? '',
          email: data['email']?.toString() ?? '',
          role: data['role']?.toString() ?? 'candidate',
        );
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

        final user = data?['user'] as Map<String, dynamic>?;
        state = AuthState.authenticated(
          userId: user?['id']?.toString() ?? '',
          email:
              user?['email']?.toString() ??
              (identifier.contains('@') ? identifier.trim() : ''),
          role: user?['role']?.toString() ?? 'candidate',
        );
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

  Future<void> logout() async {
    await _tokenStorage.clear();
    state = AuthState.unauthenticated();
  }
}
