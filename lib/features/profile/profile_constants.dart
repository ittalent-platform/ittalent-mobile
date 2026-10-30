const String profilePath = '/api/v1/me/profile';
const String changePasswordPath = '/api/v1/auth/change-password';
const int profileNameMinLength = 2;
const int profileNameMaxLength = 100;
const int avatarMaxBytes = 5 * 1024 * 1024;

final RegExp vietnamPhonePattern = RegExp(r'^0[35789]\d{8}$');
final RegExp passwordUppercasePattern = RegExp(r'[A-Z]');
final RegExp passwordLowercasePattern = RegExp(r'[a-z]');
final RegExp passwordDigitPattern = RegExp(r'\d');
final RegExp passwordSpecialPattern = RegExp(r'[!@#\$%\^&*]');

String normalizePhone(String value) =>
    value.replaceAll(RegExp(r'[\s.\-()]'), '');

bool isValidProfileName(String value) {
  final length = value.trim().length;
  return length >= profileNameMinLength && length <= profileNameMaxLength;
}

bool isValidProfilePhone(String value) {
  final phone = normalizePhone(value);
  return phone.isEmpty || vietnamPhonePattern.hasMatch(phone);
}

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

enum ProfileStatusTone { success, warning, error, neutral }

String profileRoleTranslationKey(String role) =>
    switch (role.trim().toLowerCase()) {
      'candidate' => 'profile.roles.candidate',
      'applicant' => 'profile.roles.applicant',
      'user' => 'profile.roles.user',
      'recruiter' => 'profile.roles.recruiter',
      'admin' => 'profile.roles.admin',
      _ => 'profile.roles.other',
    };

String profileStatusTranslationKey(String status) =>
    switch (status.trim().toLowerCase()) {
      'active' => 'profile.statuses.active',
      'inactive' => 'profile.statuses.inactive',
      'pending' => 'profile.statuses.pending',
      'suspended' => 'profile.statuses.suspended',
      'blocked' => 'profile.statuses.blocked',
      _ => 'profile.statuses.unknown',
    };

ProfileStatusTone profileStatusTone(String status) =>
    switch (status.trim().toLowerCase()) {
      'active' => ProfileStatusTone.success,
      'pending' => ProfileStatusTone.warning,
      'suspended' || 'blocked' => ProfileStatusTone.error,
      _ => ProfileStatusTone.neutral,
    };
