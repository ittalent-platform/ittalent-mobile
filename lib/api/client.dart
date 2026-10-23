import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_storage.dart';
import '../config/env.dart';
import 'api_error.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStorage,
    required this.dio,
    Dio? refreshDio,
  }) : _refreshDio =
           refreshDio ??
           Dio(
             BaseOptions(
               baseUrl: AppEnv.apiBaseUrl,
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 15),
               headers: {
                 'Content-Type': 'application/json',
                 'Accept': 'application/json',
               },
             ),
           );

  final TokenStorage tokenStorage;
  final Dio dio;
  final Dio _refreshDio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  Future<String?>? _refreshInFlight;

  Future<String?> _refreshAccess() async {
    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await tokenStorage.clear();
      return null;
    }
    try {
      final res = await _refreshDio.post<Map<String, Object?>>(
        '/api/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = res.data;
      final tokens = data?['tokens'] as Map<String, Object?>?;
      final access =
          (tokens?['accessToken'] ?? data?['accessToken']) as String?;
      final refresh =
          (tokens?['refreshToken'] ?? data?['refreshToken']) as String?;
      if (access == null || access.isEmpty) {
        await tokenStorage.clear();
        return null;
      }
      await tokenStorage.saveAccessToken(access);
      if (refresh != null && refresh.isNotEmpty) {
        await tokenStorage.saveRefreshToken(refresh);
      }
      return access;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        await tokenStorage.clear();
      }
      return null;
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401) return handler.next(err);
    final isAuthEndpoint =
        request.path.contains('/auth/login') ||
        request.path.contains('/auth/refresh') ||
        request.path.contains('/auth/register');
    if (isAuthEndpoint || request.extra['authRetried'] == true) {
      await tokenStorage.clear();
      return handler.next(err);
    }
    // Concurrent expired requests share a single refresh. A replay may happen once.
    final current = await tokenStorage.getAccessToken();
    String? access;
    if (current != null &&
        request.headers['Authorization'] != 'Bearer $current') {
      access = current;
    } else {
      final pending = _refreshInFlight ??= _refreshAccess();
      try {
        access = await pending;
      } finally {
        if (identical(_refreshInFlight, pending)) _refreshInFlight = null;
      }
    }
    if (access == null) return handler.next(err);
    try {
      final factory = request.extra['replayBody'];
      final body = factory is FormData Function()
          ? factory()
          : request.data is FormData
          ? (request.data as FormData).clone()
          : request.data;
      final replay = request.copyWith(
        data: body,
        headers: {...request.headers, 'Authorization': 'Bearer $access'},
        extra: {...request.extra, 'authRetried': true},
      );
      return handler.resolve(await dio.fetch<Object?>(replay));
    } on DioException catch (error) {
      return handler.next(error);
    }
  }
}

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppEnv.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(AuthInterceptor(tokenStorage: tokenStorage, dio: dio));

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio: dio);
});

class ApiClient {
  ApiClient({required this.dio});

  final Dio dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, Object?>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    }
  }
}
