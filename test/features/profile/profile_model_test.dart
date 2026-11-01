import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/profile/profile_constants.dart';
import 'package:ittalent_mobile/features/profile/profile_model.dart';

import 'profile_test_support.dart';

void main() {
  test('patch sends only changed fields and expectedVersion', () {
    final profile = testProfile();
    final nameOnly = ProfilePatch.fromValues(
      profile,
      'New Name',
      profile.phone!,
    );
    expect(nameOnly!.toJson(), {'expectedVersion': 3, 'fullName': 'New Name'});

    final phoneOnly = ProfilePatch.fromValues(
      profile,
      profile.fullName!,
      '0987 654 321',
    );
    expect(phoneOnly!.toJson(), {'expectedVersion': 3, 'phone': '0987654321'});
  });

  test('patch is null when values did not change', () {
    final profile = testProfile();
    expect(
      ProfilePatch.fromValues(profile, profile.fullName!, '0912 345 678'),
      isNull,
    );
  });

  test('Vietnamese mobile number and password rules are strict', () {
    expect(isValidProfilePhone('0912 345 678'), isTrue);
    expect(isValidProfilePhone('0212345678'), isFalse);
    expect(PasswordRules('Abcd123!').isValid, isTrue);
    expect(PasswordRules('abcd123!').isValid, isFalse);
  });
}
