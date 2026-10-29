import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ittalent_mobile/auth/auth_dto.dart';
import 'package:ittalent_mobile/features/profile/profile_model.dart';
import 'package:ittalent_mobile/features/profile/profile_repository.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';

class _TestAssetLoader extends AssetLoader {
  const _TestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(
          File('assets/translations/${locale.languageCode}.json')
              .readAsStringSync(),
        ) as Map,
      );
}

Future<void> initializeProfileTests() async {
  EasyLocalization.logger.enableLevels = [];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (call) async => call.method == 'getAll' ? <String, Object>{} : true,
      );
  await EasyLocalization.ensureInitialized();
}

MyProfile testProfile({
  ProfileAccess access = ProfileAccess.full,
  String fullName = 'Nguyen Van An',
  String phone = '0912345678',
  String role = 'candidate',
  String status = 'active',
  bool emailVerified = true,
  bool hasPassword = true,
  int version = 3,
  String? avatarUrl,
  String? enterpriseName,
}) => MyProfile(
  access: access,
  id: 'user-1',
  email: 'an@example.com',
  username: 'an.nguyen',
  fullName: fullName,
  avatarUrl: avatarUrl,
  role: role,
  status: status,
  emailVerified: emailVerified,
  phone: phone,
  version: access == ProfileAccess.full ? version : null,
  hasPassword: hasPassword,
  enterpriseName: enterpriseName,
);

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this.profile);

  MyProfile profile;
  Object? getError;
  Object? updateError;
  Object? uploadError;
  Object? passwordError;
  int getCalls = 0;
  int updateCalls = 0;
  int uploadCalls = 0;
  int passwordCalls = 0;
  ProfilePatch? lastPatch;
  Uint8List? lastAvatarBytes;
  String? lastAvatarName;
  String? lastAvatarMime;
  String? lastCurrentPassword;
  String? lastNewPassword;
  String? lastConfirmation;
  ChangePasswordResult passwordResult = const ChangePasswordResult(
    AuthTokens(accessToken: 'new-access', refreshToken: 'new-refresh'),
  );

  @override
  Future<MyProfile> getProfile() async {
    getCalls++;
    if (getError case final error?) throw error;
    return profile;
  }

  @override
  Future<MyProfile> updateProfile(ProfilePatch patch) async {
    updateCalls++;
    lastPatch = patch;
    if (updateError case final error?) throw error;
    return profile;
  }

  @override
  Future<MyProfile> uploadAvatar(
    Uint8List bytes,
    String name,
    String mimeType,
  ) async {
    uploadCalls++;
    lastAvatarBytes = bytes;
    lastAvatarName = name;
    lastAvatarMime = mimeType;
    if (uploadError case final error?) throw error;
    return profile;
  }

  @override
  Future<ChangePasswordResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    passwordCalls++;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    lastConfirmation = confirmation;
    if (passwordError case final error?) throw error;
    return passwordResult;
  }
}

Widget localizedApp({required List<Object> overrides, required Widget home}) =>
    ProviderScope(
      overrides: overrides.cast(),
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('vi')],
        path: 'assets/translations',
        assetLoader: const _TestAssetLoader(),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            theme: AppTheme.light,
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            home: home,
          ),
        ),
      ),
    );

Widget localizedRouterApp({
  required List<Object> overrides,
  required GoRouter router,
}) => ProviderScope(
  overrides: overrides.cast(),
  child: EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('vi')],
    path: 'assets/translations',
    assetLoader: const _TestAssetLoader(),
    startLocale: const Locale('en'),
    saveLocale: false,
    child: Builder(
      builder: (context) => MaterialApp.router(
        theme: AppTheme.light,
        locale: context.locale,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        routerConfig: router,
      ),
    ),
  ),
);
