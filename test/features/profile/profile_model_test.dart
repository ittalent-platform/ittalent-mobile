import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/profile/profile_constants.dart';
import 'package:ittalent_mobile/features/profile/profile_model.dart';

void main() {
  final basic = <String, Object?>{
    'access': 'basic',
    'id': 'u1',
    'email': 'u@example.com',
    'username': 'user',
    'fullName': 'User Name',
    'avatarUrl': null,
    'role': 'candidate',
    'status': 'active',
    'emailVerified': false,
  };
  final full = <String, Object?>{
    ...basic,
    'access': 'full',
    'emailVerified': true,
    'version': 3,
    'phone': '0912345678',
    'hasPassword': true,
    'enterpriseId': null,
    'enterpriseName': null,
  };
  test('parses basic and full projections', () {
    expect(MyProfile.fromJson(basic).canMutate, isFalse);
    expect(MyProfile.fromJson(full).canMutate, isTrue);
  });
  test('normalizes phone and emits only changed patch fields', () {
    final profile = MyProfile.fromJson(full);
    expect(normalizePhone('0912 345-678'), '0912345678');
    final patch = ProfilePatch.fromValues(profile, 'New Name', '');
    expect(patch!.toJson(), {
      'expectedVersion': 3,
      'fullName': 'New Name',
      'phone': null,
    });
  });
  test('password rules accept all required groups', () {
    expect(PasswordRules('Abcd123!').isValid, isTrue);
    expect(PasswordRules('abcd123!').isValid, isFalse);
  });
  test('avatar type and inclusive size validation', () {
    expect(
      isAllowedAvatarFile(length: avatarMaxBytes, mimeType: 'image/png'),
      isTrue,
    );
    expect(
      isAllowedAvatarFile(length: avatarMaxBytes + 1, mimeType: 'image/png'),
      isFalse,
    );
    expect(isAllowedAvatarFile(length: 1, mimeType: 'image/gif'), isFalse);
  });
}
