import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../api/client.dart';
import 'profile_constants.dart';
import 'profile_model.dart';

class ProfileRepository {
  const ProfileRepository(this._api);
  final ApiClient _api;
  Map<String, Object?> _map(Object? value) =>
      Map<String, Object?>.from(value as Map);
  Future<MyProfile> getProfile() async => MyProfile.fromJson(
    _map((await _api.get<Map<String, Object?>>(profilePath)).data),
  );
  Future<MyProfile> updateProfile(ProfilePatch patch) async =>
      MyProfile.fromJson(
        _map(
          (await _api.patch<Map<String, Object?>>(
            profilePath,
            data: patch.toJson(),
          )).data,
        ),
      );
  Future<MyProfile> uploadAvatar(
    Uint8List bytes,
    String name,
    String mimeType,
  ) async {
    final data = FormData.fromMap({
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
          data: data,
          options: Options(
            extra: {
              'replayBody': () => FormData.fromMap({
                'avatar': MultipartFile.fromBytes(
                  bytes,
                  filename: name,
                  contentType: DioMediaType.parse(mimeType),
                ),
              }),
            },
          ),
        )).data,
      ),
    );
  }

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
