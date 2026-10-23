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
import 'documents_repository_test.dart' show StreamingAdapter;

void main() {
  for (final extension in ['pdf', 'doc', 'docx']) {
    for (final type in DocumentType.values) {
      test(
        'multipart $extension ${type.value}: exact fields, MIME, filename, auth and bytes',
        () async {
          final file = selected(extension);
          final dio = Dio(BaseOptions(baseUrl: 'http://test'));
          dio.interceptors.add(
            AuthInterceptor(
              tokenStorage: InMemoryTokenStorage(accessToken: 'access'),
              dio: dio,
            ),
          );
          dio.httpClientAdapter = StreamingAdapter((options, body) async {
            expect(options.method, 'POST');
            expect(options.path, DocumentConstants.path);
            expect(options.headers['Authorization'], 'Bearer access');
            expect(
              options.contentType,
              contains('multipart/form-data; boundary='),
            );
            final form = options.data as FormData;
            expect(Map.fromEntries(form.fields), {'type': type.value});
            expect(form.files.length, 1);
            expect(form.files.single.key, 'file');
            expect(form.files.single.value.filename, file.name);
            expect(
              form.files.single.value.contentType.toString(),
              file.mimeType,
            );
            expect(body, containsAllInOrder(await file.readBytes()));
            return jsonBody(documentJson(type: type.value), status: 201);
          });
          final result = await DocumentsRepository(ApiClient(dio: dio))
              .upload(file, type);
          expect(result.type, type);
        },
      );
    }
  }
  test('client validation 0/exact limit/over limit/unsupported/forged/stale metadata; invalid never calls HTTP', () async {
    var calls = 0;
    final dio = Dio()
      ..httpClientAdapter = FakeAdapter((_) {
        calls++;
        return jsonBody(documentJson(), status: 201);
      });
    final repo = DocumentsRepository(ApiClient(dio: dio));
    for (final file in [
      selected('pdf', size: 0),
      selected('pdf', size: 5242881),
      selected('txt'),
      selected('pdf', bytes: Uint8List.fromList([1, 2, 3])),
      SelectedDocument(
        name: 'a.pdf',
        size: 5,
        readBytes: () async => Uint8List(0),
      ),
      SelectedDocument(
        name: 'revoked.pdf',
        size: 5,
        readBytes: () async => throw StateError('provider access lost'),
      ),
    ]) {
      await expectLater(
        repo.upload(file, DocumentType.cv),
        throwsA(isA<DocumentValidation>()),
      );
    }
    expect(calls, 0);
    final bytes = Uint8List(5242880)
      ..setAll(0, DocumentConstants.signatures['pdf']!);
    await repo.upload(selected('pdf', bytes: bytes), DocumentType.cv);
    expect(calls, 1);
  });
  test(
    'upload accepts only 201; manual retry reconstructs multipart',
    () async {
      final bodies = <FormData>[];
      var calls = 0;
      final dio = Dio()
        ..httpClientAdapter = StreamingAdapter((o, b) async {
          bodies.add(o.data as FormData);
          calls++;
          return jsonBody(
            documentJson(),
            status: calls == 1
                ? 502
                : calls == 2
                ? 200
                : 201,
          );
        });
      final repo = DocumentsRepository(ApiClient(dio: dio));
      await expectLater(
        repo.upload(selected('docx'), DocumentType.coverLetter),
        throwsA(isA<ApiError>()),
      );
      await expectLater(
        repo.upload(selected('docx'), DocumentType.coverLetter),
        throwsA(isA<ApiError>()),
      );
      await repo.upload(selected('docx'), DocumentType.coverLetter);
      expect(bodies.toSet().length, 3);
      expect(calls, 3);
    },
  );
  for (final status in [400, 401, 403, 404, 502]) {
    test(
      'upload backend error $status mapped without automatic retry',
      () async {
        var calls = 0;
        final dio = Dio()
          ..httpClientAdapter = FakeAdapter((_) {
            calls++;
            return jsonBody({'message': 'Rejected'}, status: status);
          });
        await expectLater(
          DocumentsRepository(ApiClient(dio: dio))
              .upload(selected('pdf'), DocumentType.cv),
          throwsA(
            isA<ApiError>().having((e) => e.statusCode, 'status', status),
          ),
        );
        expect(calls, 1);
      },
    );
  }
}
