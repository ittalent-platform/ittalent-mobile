import 'auth_dto.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.status, this.user, this.errorMessage});

  final AuthStatus status;
  final UserDTO? user;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get isEmailVerified => user?.emailVerified ?? false;

  String? get userId => user?.id;
  String? get email => user?.email;
  String? get role => user?.role;
  String? get username => user?.username;
  String? get fullName => user?.fullName;

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  factory AuthState.unauthenticated([String? error]) =>
      AuthState(status: AuthStatus.unauthenticated, errorMessage: error);

  factory AuthState.authenticated({
    UserDTO? user,
    String? userId,
    String? email,
    String? role,
  }) {
    final effectiveUser =
        user ??
        UserDTO(
          id: userId ?? '',
          email: email ?? '',
          username: '',
          role: role ?? 'candidate',
        );
    return AuthState(status: AuthStatus.authenticated, user: effectiveUser);
  }

  AuthState copyWith({
    AuthStatus? status,
    UserDTO? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
