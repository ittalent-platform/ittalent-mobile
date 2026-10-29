import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/features/profile/profile_constants.dart';
import 'package:ittalent_mobile/features/profile/profile_model.dart';
import 'package:ittalent_mobile/features/profile/profile_repository.dart';

class _ApiClient extends ApiClient {
  _ApiClient() : super(dio: Dio());

  String? path;
  Object? body;

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    this.path = path;
    body = data;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: <String, Object?>{
        'access': 'full',
        'id': 'u1',
        'email': 'u@example.com',
        'username': 'user',
        'fullName': 'New Name',
        'avatarUrl': null,
        'role': 'candidate',
        'status': 'active',
        'emailVerified': true,
        'phone': '0912345678',
        'version': 4,
      } as T,
    );
  }
}

void main() {
  test('PATCH sends only the changed field and expectedVersion', () async {
    final api = _ApiClient();
    final repository = ApiProfileRepository(api);
    await repository.updateProfile(
      const ProfilePatch(
        expectedVersion: 3,
        fullName: 'New Name',
        includeFullName: true,
        includePhone: false,
      ),
    );
    expect(api.path, profilePath);
    expect(api.body, {'expectedVersion': 3, 'fullName': 'New Name'});
  });
}
