import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/auth/auth_dto.dart';

void main() {
  group('Auth DTO Tests', () {
    test('LoginRequest serializes correctly with trimmed identifier', () {
      const req = LoginRequest(
        identifier: '  alex_dev  ',
        password: 'Password123!',
      );
      expect(req.toJson(), {
        'identifier': 'alex_dev',
        'password': 'Password123!',
      });
    });

    test('RegisterRequest serializes with lowercase email and username', () {
      const req = RegisterRequest(
        email: '  Alex@Example.COM  ',
        username: '  ALEX_DEV  ',
        password: 'Password123!',
      );
      expect(req.toJson(), {
        'email': 'alex@example.com',
        'username': 'alex_dev',
        'password': 'Password123!',
      });
    });

    test('ForgotPasswordRequest serializes correctly', () {
      const req = ForgotPasswordRequest(email: 'User@Test.Com');
      expect(req.toJson(), {'email': 'user@test.com'});
    });

    test('ResetPasswordRequest serializes correctly', () {
      const req = ResetPasswordRequest(
        token: 'token-123',
        newPassword: 'NewPassword123!',
      );
      expect(req.toJson(), {
        'token': 'token-123',
        'newPassword': 'NewPassword123!',
      });
    });

    test('AuthTokens deserializes and serializes correctly', () {
      final json = {
        'accessToken': 'access-token-jwt',
        'refreshToken': 'refresh-token-jwt',
      };
      final tokens = AuthTokens.fromJson(json);
      expect(tokens.accessToken, 'access-token-jwt');
      expect(tokens.refreshToken, 'refresh-token-jwt');
      expect(tokens.toJson(), json);
    });

    test('UserDTO deserializes complete payload correctly', () {
      final json = {
        'id': 'usr-1',
        'email': 'alex@example.com',
        'username': 'alex_dev',
        'fullName': 'Alex Doe',
        'phone': '0901234567',
        'role': 'candidate',
        'status': 'active',
        'emailVerified': true,
        'enterpriseId': 'ent-1',
        'enterpriseName': 'Tech Corp',
      };
      final user = UserDTO.fromJson(json);
      expect(user.id, 'usr-1');
      expect(user.email, 'alex@example.com');
      expect(user.username, 'alex_dev');
      expect(user.fullName, 'Alex Doe');
      expect(user.phone, '0901234567');
      expect(user.role, 'candidate');
      expect(user.status, 'active');
      expect(user.emailVerified, isTrue);
      expect(user.enterpriseId, 'ent-1');
      expect(user.enterpriseName, 'Tech Corp');
    });

    test('AuthResponse deserializes nested user and tokens', () {
      final json = {
        'user': {
          'id': 'usr-1',
          'email': 'alex@example.com',
          'username': 'alex_dev',
          'role': 'candidate',
        },
        'tokens': {'accessToken': 'access-123', 'refreshToken': 'refresh-123'},
      };
      final res = AuthResponse.fromJson(json);
      expect(res.user.id, 'usr-1');
      expect(res.tokens.accessToken, 'access-123');
    });

    test('RegisterResponse deserializes verification email sent flag', () {
      final json = {
        'user': {
          'id': 'usr-1',
          'email': 'alex@example.com',
          'username': 'alex_dev',
          'role': 'candidate',
        },
        'tokens': {'accessToken': 'access-123', 'refreshToken': 'refresh-123'},
        'verificationEmailSent': true,
      };
      final res = RegisterResponse.fromJson(json);
      expect(res.verificationEmailSent, isTrue);
    });

    test('ResetPasswordTokenResponse parses valid boolean from data', () {
      final json = {
        'success': true,
        'message': 'Token is valid',
        'data': {'valid': true},
      };
      final res = ResetPasswordTokenResponse.fromJson(json);
      expect(res.success, isTrue);
      expect(res.valid, isTrue);
      expect(res.message, 'Token is valid');
    });
  });
}
