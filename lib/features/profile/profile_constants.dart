const String profilePath = '/api/v1/me/profile';
const String changePasswordPath = '/api/v1/auth/change-password';
const int profileNameMinLength = 2;
const int profileNameMaxLength = 100;
const int avatarMaxBytes = 5 * 1024 * 1024;
const Set<String> avatarMimeTypes = {'image/jpeg', 'image/png', 'image/webp'};
final RegExp vietnamPhonePattern = RegExp(r'^0[35789]\d{8}$');
final RegExp passwordUppercasePattern = RegExp(r'[A-Z]');
final RegExp passwordLowercasePattern = RegExp(r'[a-z]');
final RegExp passwordDigitPattern = RegExp(r'\d');
final RegExp passwordSpecialPattern = RegExp(r'[!@#\$%\^&*]');

String normalizePhone(String value) =>
    value.replaceAll(RegExp(r'[\s.\-()]'), '');

class PasswordRules {
  const PasswordRules(this.value);
  final String value;
  bool get length => value.length >= 8 && value.length <= 64;
  bool get uppercase => passwordUppercasePattern.hasMatch(value);
  bool get lowercase => passwordLowercasePattern.hasMatch(value);
  bool get digit => passwordDigitPattern.hasMatch(value);
  bool get special => passwordSpecialPattern.hasMatch(value);
  bool get isValid => length && uppercase && lowercase && digit && special;
}

bool isAllowedAvatarFile({required int length, required String mimeType}) =>
    length <= avatarMaxBytes && avatarMimeTypes.contains(mimeType);
