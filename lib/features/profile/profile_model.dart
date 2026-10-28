import '../../auth/auth_dto.dart';
import 'profile_constants.dart';

enum ProfileAccess { basic, full }

class MyProfile {
  const MyProfile({
    required this.access,
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
    required this.role,
    required this.status,
    required this.emailVerified,
    this.phone,
    this.version,
    this.hasPassword = false,
    this.enterpriseId,
    this.enterpriseName,
  });

  final ProfileAccess access;
  final String id;
  final String email;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String role;
  final String status;
  final bool emailVerified;
  final String? phone;
  final int? version;
  final bool hasPassword;
  final String? enterpriseId;
  final String? enterpriseName;

  bool get canMutate =>
      access == ProfileAccess.full && emailVerified && status == 'active';
  String get displayName =>
      (fullName?.trim().isNotEmpty ?? false) ? fullName!.trim() : username;

  factory MyProfile.fromJson(Map<String, Object?> json) {
    final accessValue = json['access']?.toString();
    if (accessValue != 'basic' && accessValue != 'full') {
      throw const FormatException('Invalid profile access projection');
    }
    String required(String key) {
      final value = json[key]?.toString() ?? '';
      if (value.isEmpty) throw FormatException('Missing profile $key');
      return value;
    }

    final isFull = accessValue == 'full';
    if (isFull && json['version'] == null) {
      throw const FormatException('Missing profile version');
    }
    return MyProfile(
      access: isFull ? ProfileAccess.full : ProfileAccess.basic,
      id: required('id'),
      email: required('email'),
      username: required('username'),
      fullName: json['fullName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      role: required('role'),
      status: required('status'),
      emailVerified: json['emailVerified'] == true,
      phone: json['phone']?.toString(),
      version: int.tryParse(json['version']?.toString() ?? ''),
      hasPassword: json['hasPassword'] == true,
      enterpriseId: json['enterpriseId']?.toString(),
      enterpriseName: json['enterpriseName']?.toString(),
    );
  }
}

class ProfilePatch {
  const ProfilePatch({
    required this.expectedVersion,
    this.fullName,
    this.phone,
    required this.includeFullName,
    required this.includePhone,
  });
  final int expectedVersion;
  final String? fullName;
  final String? phone;
  final bool includeFullName;
  final bool includePhone;
  Map<String, Object?> toJson() => {
    'expectedVersion': expectedVersion,
    if (includeFullName) 'fullName': fullName,
    if (includePhone) 'phone': phone,
  };
  static ProfilePatch? fromValues(
    MyProfile profile,
    String fullName,
    String phone,
  ) {
    final cleanName = fullName.trim();
    final cleanPhone = normalizePhone(phone);
    final changedName = cleanName != (profile.fullName ?? '');
    final changedPhone = cleanPhone != (profile.phone ?? '');
    if ((!changedName && !changedPhone) || profile.version == null) {
      return null;
    }
    return ProfilePatch(
      expectedVersion: profile.version!,
      fullName: cleanName,
      phone: cleanPhone.isEmpty ? null : cleanPhone,
      includeFullName: changedName,
      includePhone: changedPhone,
    );
  }
}

class ChangePasswordResult {
  const ChangePasswordResult(this.tokens);
  final AuthTokens tokens;
  factory ChangePasswordResult.fromJson(Map<String, Object?> json) {
    final data = json['data'];
    if (data is! Map<String, Object?> ||
        data['tokens'] is! Map<String, Object?>) {
      throw const FormatException('Missing replacement tokens');
    }
    final tokens = AuthTokens.fromJson(data['tokens']! as Map<String, dynamic>);
    if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
      throw const FormatException('Invalid replacement tokens');
    }
    return ChangePasswordResult(tokens);
  }
}
