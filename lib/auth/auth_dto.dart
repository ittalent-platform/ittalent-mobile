class LoginRequest {
  const LoginRequest({required this.identifier, required this.password});

  final String identifier;
  final String password;

  Map<String, dynamic> toJson() => {
    'identifier': identifier.trim(),
    'password': password,
  };
}

class RegisterRequest {
  const RegisterRequest({
    required this.email,
    required this.username,
    required this.password,
  });

  final String email;
  final String username;
  final String password;

  Map<String, dynamic> toJson() => {
    'email': email.trim().toLowerCase(),
    'username': username.trim().toLowerCase(),
    'password': password,
  };
}

class ForgotPasswordRequest {
  const ForgotPasswordRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email.trim().toLowerCase()};
}

class ResetPasswordRequest {
  const ResetPasswordRequest({required this.token, required this.newPassword});

  final String token;
  final String newPassword;

  Map<String, dynamic> toJson() => {'token': token, 'newPassword': newPassword};
}

class ResendVerificationEmailRequest {
  const ResendVerificationEmailRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email.trim().toLowerCase()};
}

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };
}

class UserDTO {
  const UserDTO({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    this.phone,
    required this.role,
    this.status = 'active',
    this.emailVerified = false,
    this.enterpriseId,
    this.enterpriseName,
  });

  final String id;
  final String email;
  final String username;
  final String? fullName;
  final String? phone;
  final String role;
  final String status;
  final bool emailVerified;
  final String? enterpriseId;
  final String? enterpriseName;

  factory UserDTO.fromJson(Map<String, dynamic> json) {
    return UserDTO(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'candidate',
      status: json['status']?.toString() ?? 'active',
      emailVerified: json['emailVerified'] == true,
      enterpriseId: json['enterpriseId']?.toString(),
      enterpriseName: json['enterpriseName']?.toString(),
    );
  }

  UserDTO copyWith({
    String? id,
    String? email,
    String? username,
    String? fullName,
    String? phone,
    String? role,
    String? status,
    bool? emailVerified,
    String? enterpriseId,
    String? enterpriseName,
  }) {
    return UserDTO(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      emailVerified: emailVerified ?? this.emailVerified,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      enterpriseName: enterpriseName ?? this.enterpriseName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    if (fullName != null) 'fullName': fullName,
    if (phone != null) 'phone': phone,
    'role': role,
    'status': status,
    'emailVerified': emailVerified,
    if (enterpriseId != null) 'enterpriseId': enterpriseId,
    if (enterpriseName != null) 'enterpriseName': enterpriseName,
  };
}

class AuthResponse {
  const AuthResponse({required this.user, required this.tokens});

  final UserDTO user;
  final AuthTokens tokens;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserDTO.fromJson(
        (json['user'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      tokens: AuthTokens.fromJson(
        (json['tokens'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }
}

class RegisterResponse {
  const RegisterResponse({
    required this.user,
    required this.tokens,
    required this.verificationEmailSent,
  });

  final UserDTO user;
  final AuthTokens tokens;
  final bool verificationEmailSent;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      user: UserDTO.fromJson(
        (json['user'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      tokens: AuthTokens.fromJson(
        (json['tokens'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      verificationEmailSent: json['verificationEmailSent'] == true,
    );
  }
}

class ResetPasswordTokenResponse {
  const ResetPasswordTokenResponse({
    required this.success,
    required this.valid,
    this.message,
  });

  final bool success;
  final bool valid;
  final String? message;

  factory ResetPasswordTokenResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return ResetPasswordTokenResponse(
      success: json['success'] == true,
      valid: data?['valid'] == true,
      message: json['message']?.toString(),
    );
  }
}

enum LoginResultStatus {
  success,
  invalidCredentials,
  webRoleNotSupported,
  error,
}

class LoginResult {
  const LoginResult({required this.status, this.errorMessage, this.role});

  final LoginResultStatus status;
  final String? errorMessage;
  final String? role;

  bool get isSuccess => status == LoginResultStatus.success;
  bool get isWebRoleNotSupported =>
      status == LoginResultStatus.webRoleNotSupported;
}

bool isAllowedMobileApplicantRole(String? role) {
  if (role == null) return false;
  final normalized = role.trim().toLowerCase();
  return normalized == 'user' ||
      normalized == 'applicant' ||
      normalized == 'candidate';
}
