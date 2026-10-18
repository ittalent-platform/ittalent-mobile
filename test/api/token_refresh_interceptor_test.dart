import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/auth/token_storage.dart';

class InMemoryTokenStorage extends TokenStorage {
  InMemoryTokenStorage({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<void> saveAccessToken(String token) async {
    accessToken = token;
  }

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveRefreshToken(String token) async {
    refreshToken = token;
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
}

class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter({required this.handler});

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<dynamic>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('AuthInterceptor Tests', () {
    late InMemoryTokenStorage tokenStorage;
    late Dio mainDio;
    late Dio refreshDio;

    setUp(() {
      tokenStorage = InMemoryTokenStorage(
        accessToken: 'initial-access-token',
        refreshToken: 'initial-refresh-token',
      );
      mainDio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      refreshDio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    });

    test('attaches Authorization header when accessToken exists', () async {
      mainDio.httpClientAdapter = FakeHttpAdapter(
        handler: (options) async {
          expect(
            options.headers['Authorization'],
            'Bearer initial-access-token',
          );
          return ResponseBody.fromString(
            '{"ok":true}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        },
      );

      mainDio.interceptors.add(
        AuthInterceptor(
          tokenStorage: tokenStorage,
          dio: mainDio,
          refreshDio: refreshDio,
        ),
      );

      final response = await mainDio.get<Map<String, dynamic>>('/api/v1/jobs');
      expect(response.statusCode, 200);
    });

    test(
      'does not attach Authorization header when accessToken is empty',
      () async {
        tokenStorage.accessToken = null;

        mainDio.httpClientAdapter = FakeHttpAdapter(
          handler: (options) async {
            expect(options.headers.containsKey('Authorization'), isFalse);
            return ResponseBody.fromString(
              '{"ok":true}',
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          },
        );

        mainDio.interceptors.add(
          AuthInterceptor(
            tokenStorage: tokenStorage,
            dio: mainDio,
            refreshDio: refreshDio,
          ),
        );

        final response = await mainDio.get<Map<String, dynamic>>(
          '/api/v1/jobs',
        );
        expect(response.statusCode, 200);
      },
    );

    test('refreshes token on 401 and replays original request', () async {
      var profileAttempts = 0;

      refreshDio.httpClientAdapter = FakeHttpAdapter(
        handler: (options) async {
          expect(options.path, '/api/v1/auth/refresh');
          return ResponseBody.fromString(
            '{"tokens":{"accessToken":"refreshed-access","refreshToken":"refreshed-refresh"}}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        },
      );

      mainDio.httpClientAdapter = FakeHttpAdapter(
        handler: (options) async {
          if (options.path.contains('/api/v1/profile')) {
            profileAttempts++;
            if (profileAttempts == 1) {
              return ResponseBody.fromString(
                '{"error":"Unauthorized"}',
                401,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            } else {
              expect(
                options.headers['Authorization'],
                'Bearer refreshed-access',
              );
              return ResponseBody.fromString(
                '{"id":"usr-1","name":"Alex"}',
                200,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            }
          }
          return ResponseBody.fromString('{}', 404);
        },
      );

      mainDio.interceptors.add(
        AuthInterceptor(
          tokenStorage: tokenStorage,
          dio: mainDio,
          refreshDio: refreshDio,
        ),
      );

      final res = await mainDio.get<Map<String, dynamic>>('/api/v1/profile');
      expect(res.statusCode, 200);
      expect(profileAttempts, 2);
      expect(tokenStorage.accessToken, 'refreshed-access');
      expect(tokenStorage.refreshToken, 'refreshed-refresh');
    });

    test('clears storage when refresh fails with 401', () async {
      refreshDio.httpClientAdapter = FakeHttpAdapter(
        handler: (options) async {
          return ResponseBody.fromString(
            '{"error":"Invalid refresh token"}',
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        },
      );

      mainDio.httpClientAdapter = FakeHttpAdapter(
        handler: (options) async {
          return ResponseBody.fromString(
            '{"error":"Unauthorized"}',
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        },
      );

      mainDio.interceptors.add(
        AuthInterceptor(
          tokenStorage: tokenStorage,
          dio: mainDio,
          refreshDio: refreshDio,
        ),
      );

      try {
        await mainDio.get<dynamic>('/api/v1/profile');
        fail('Should throw DioException');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 401);
      }

      expect(tokenStorage.accessToken, isNull);
      expect(tokenStorage.refreshToken, isNull);
    });

    test(
      'clears storage without calling refresh when login receives 401',
      () async {
        var refreshCalled = false;

        refreshDio.httpClientAdapter = FakeHttpAdapter(
          handler: (options) async {
            refreshCalled = true;
            return ResponseBody.fromString('{}', 200);
          },
        );

        mainDio.httpClientAdapter = FakeHttpAdapter(
          handler: (options) async {
            return ResponseBody.fromString(
              '{"error":"Invalid credentials"}',
              401,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          },
        );

        mainDio.interceptors.add(
          AuthInterceptor(
            tokenStorage: tokenStorage,
            dio: mainDio,
            refreshDio: refreshDio,
          ),
        );

        try {
          await mainDio.post<dynamic>('/api/v1/auth/login');
          fail('Should throw DioException');
        } on DioException catch (e) {
          expect(e.response?.statusCode, 401);
        }

        expect(refreshCalled, isFalse);
        expect(tokenStorage.accessToken, isNull);
        expect(tokenStorage.refreshToken, isNull);
      },
    );
  });
}
