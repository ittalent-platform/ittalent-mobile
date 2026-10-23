import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/api/api_error.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_files.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_model.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_constants.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_repository.dart';

import '../../../api/token_refresh_interceptor_test.dart'
    show InMemoryTokenStorage;
import '../../../helpers/fake_api.dart';

import 'documents_test_data.dart';
import 'documents_upload_data.dart';

void main() {
  for (final status in [400, 401, 403, 404, 502]) {
    test(
      'download JSON error bytes $status decoded, never treated as file',
      () async {
        final dio = Dio()
          ..httpClientAdapter = FakeAdapter(
            (_) => jsonBody({
              'success': false,
              'message': 'Document not found',
            }, status: status),
          );
        await expectLater(
          DocumentsRepository(ApiClient(dio: dio))
              .download(DocumentDto.fromJson(documentJson())),
          throwsA(
            isA<ApiError>()
                .having((e) => e.statusCode, 'status', status)
                .having((e) => e.message, 'message', 'Document not found'),
          ),
        );
      },
    );
  }
  for (final errorType in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.connectionError,
  ]) {
    test('network $errorType propagates for list/upload/download', () async {
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter(
          (o) => throw DioException(requestOptions: o, type: errorType),
        );
      final repo = DocumentsRepository(ApiClient(dio: dio));
      await expectLater(
        repo.list(const DocumentsQuery(), 1),
        throwsA(isA<ApiError>()),
      );
      await expectLater(
        repo.upload(selected('pdf'), DocumentType.cv),
        throwsA(isA<ApiError>()),
      );
      await expectLater(
        repo.download(DocumentDto.fromJson(documentJson())),
        throwsA(isA<ApiError>()),
      );
    });
  }
  test('download endpoint, auth, bytes/MIME, Unicode disposition without content-length', () async {
    final bytes = Uint8List.fromList([0, 1, 255, 13, 10]);
    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: InMemoryTokenStorage(accessToken: 'access'),
        dio: dio,
      ),
    );
    dio.httpClientAdapter = FakeAdapter((o) {
      expect(
        o.path,
        '${DocumentConstants.path}/507f1f77bcf86cd799439011/download',
      );
      expect(o.headers['Authorization'], 'Bearer access');
      expect(o.responseType, ResponseType.bytes);
      expect(o.headers['Accept'], contains('application/msword'));
      return ResponseBody.fromBytes(
        bytes,
        200,
        headers: {
          'content-type': ['application/msword'],
          'content-disposition': [
            "attachment; filename=ascii.doc; filename*=UTF-8''Nguy%E1%BB%85n%20An.doc",
          ],
        },
      );
    });
    final result = await DocumentsRepository(ApiClient(dio: dio))
        .download(DocumentDto.fromJson(documentJson()));
    expect(result.bytes, bytes);
    expect(result.name, 'Nguyễn An.doc');
    expect(result.mimeType, 'application/msword');
  });
  test(
    'filename fallback, traversal, invalid UTF-8, reserved Windows names',
    () {
      expect(
        documentFileName(null, 'CV tiếng Việt.docx'),
        'CV tiếng Việt.docx',
      );
      expect(
        documentFileName('attachment; filename="../../cv.pdf"', 'x.pdf'),
        isNot(contains('/')),
      );
      expect(
        documentFileName(
          "attachment; filename*=UTF-8''%ZZ; filename=plain.doc",
          'x.pdf',
        ),
        'plain.doc',
      );
      expect(
        documentFileName('attachment; filename="CON.pdf"', 'x.pdf'),
        '_CON.pdf',
      );
      expect(documentFileName('attachment; filename="..."', 'x.pdf'), 'x.pdf');
    },
  );
  for (final kind in ['empty', 'truncated', 'json']) {
    test('download rejects $kind response before save', () async {
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter(
          (_) => ResponseBody.fromBytes(
            kind == 'empty' ? [] : [1, 2],
            200,
            headers: {
              'content-type': [
                kind == 'json' ? 'application/json' : 'application/pdf',
              ],
              if (kind == 'truncated') 'content-length': ['10'],
            },
          ),
        );
      await expectLater(
        DocumentsRepository(ApiClient(dio: dio))
            .download(DocumentDto.fromJson(documentJson())),
        throwsA(isA<ApiError>()),
      );
    });
  }
}
