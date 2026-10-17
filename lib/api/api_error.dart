import 'package:dio/dio.dart';

class ApiError implements Exception {
  const ApiError({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final dynamic details;

  factory ApiError.fromDio(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    
    String message = 'An unexpected error occurred. Please try again.';
    String? code;
    dynamic details;

    if (response?.data is Map<String, dynamic>) {
      final map = response!.data as Map<String, dynamic>;
      message = map['message']?.toString() ?? message;
      code = map['code']?.toString();
      details = map['details'];
    } else if (response?.statusMessage != null) {
      message = response!.statusMessage!;
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timed out. Please check your internet.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Unable to connect to the server.';
    }

    return ApiError(
      message: message,
      statusCode: statusCode,
      code: code,
      details: details,
    );
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'ApiError(status: $statusCode, code: $code, message: $message)';
}
