import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../api/client.dart';
import 'profile_constants.dart';
import 'profile_model.dart';

abstract interface class ProfileRepository {
  Future<MyProfile> getProfile();
  Future<MyProfile> updateProfile(ProfilePatch patch);
  Future<MyProfile> uploadAvatar(Uint8List bytes, String name, String mimeType);
  Future<ChangePasswordResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  });
}

class ApiProfileRepository implements ProfileRepository {
  const ApiProfileRepository(this._api);

  final ApiClient _api;

  Map<String, Object?> _map(Object? value) {
    if (value is! Map<Object?, Object?>) {
      throw const FormatException('Invalid profile response');
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  @override
  Future<MyProfile> getProfile() async => MyProfile.fromJson(
    _map((await _api.get<Map<String, Object?>>(profilePath)).data),
  );

  @override
  Future<MyProfile> updateProfile(ProfilePatch patch) async =>
      MyProfile.fromJson(
        _map(
          (await _api.patch<Map<String, Object?>>(
            profilePath,
            data: patch.toJson(),
          )).data,
        ),
      );

  @override
  Future<MyProfile> uploadAvatar(
    Uint8List bytes,
    String name,
    String mimeType,
  ) async {
    FormData body() => FormData.fromMap({
      'avatar': MultipartFile.fromBytes(
        bytes,
        filename: name,
        contentType: DioMediaType.parse(mimeType),
      ),
    });

    return MyProfile.fromJson(
      _map(
        (await _api.patch<Map<String, Object?>>(
          '$profilePath/avatar',
          data: body(),
          options: Options(extra: {'replayBody': body}),
        )).data,
      ),
    );
  }

  @override
  Future<ChangePasswordResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async => ChangePasswordResult.fromJson(
    _map(
      (await _api.post<Map<String, Object?>>(
        changePasswordPath,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmation': confirmation,
        },
      )).data,
    ),
  );
}
