enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.userId,
    this.email,
    this.role,
    this.errorMessage,
  });

  final AuthStatus status;
  final String? userId;
  final String? email;
  final String? role;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.unauthenticated([String? error]) =>
      AuthState(status: AuthStatus.unauthenticated, errorMessage: error);
  factory AuthState.authenticated({
    required String userId,
    required String email,
    required String role,
  }) => AuthState(
    status: AuthStatus.authenticated,
    userId: userId,
    email: email,
    role: role,
  );

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? email,
    String? role,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      role: role ?? this.role,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
