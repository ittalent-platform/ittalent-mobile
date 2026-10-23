import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_model.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_repository.dart';

import '../../../api/token_refresh_interceptor_test.dart'
    show InMemoryTokenStorage;
import '../../../helpers/fake_api.dart';

import 'documents_test_data.dart';
import 'documents_upload_data.dart';
import 'documents_repository_test.dart' show StreamingAdapter;

void main() {
  for (final multipart in [true]) {
    test(
      '401 refresh preserves ${multipart ? 'multipart body' : 'binary options'}, callbacks, cancellation, query; retries once',
      () async {
        final tokens = InMemoryTokenStorage(
          accessToken: 'old',
          refreshToken: 'refresh',
        );
        final dio = Dio(BaseOptions(baseUrl: 'http://test'));
        final refresh = Dio();
        var attempts = 0;
        final bodies = <Uint8List>[];
        refresh.httpClientAdapter = FakeAdapter(
          (_) => jsonBody({
            'tokens': {'accessToken': 'new'},
          }),
        );
        dio.interceptors.add(
          AuthInterceptor(tokenStorage: tokens, dio: dio, refreshDio: refresh),
        );
        final cancel = CancelToken();
        dio.httpClientAdapter = StreamingAdapter((o, body) async {
          attempts++;
          bodies.add(body);
          expect(o.cancelToken, same(cancel));
          if (attempts == 1) {
            return jsonBody({'message': 'expired'}, status: 401);
          }
          expect(o.headers['Authorization'], 'Bearer new');
          if (!multipart) expect(o.responseType, ResponseType.bytes);
          return multipart
              ? jsonBody(documentJson(), status: 201)
              : ResponseBody.fromBytes(
                  [0, 255, 1],
                  200,
                  headers: {
                    'content-type': ['application/pdf'],
                  },
                );
        });
        final repo = DocumentsRepository(ApiClient(dio: dio));
        if (multipart) {
          await repo.upload(
            selected('docx'),
            DocumentType.coverLetter,
            cancelToken: cancel,
          );
          expect(bodies.every((b) => b.isNotEmpty), true);
        }
        expect(attempts, 2);
        expect(tokens.accessToken, 'new');
      },
    );
  }
  test(
    'repeated 401 stops without deadlock; replay 502 does not clear good token',
    () async {
      for (final status in [401, 502]) {
        final tokens = InMemoryTokenStorage(
          accessToken: 'old',
          refreshToken: 'refresh',
        );
        final dio = Dio();
        final refresh = Dio();
        var calls = 0;
        refresh.httpClientAdapter = FakeAdapter(
          (_) => jsonBody({'accessToken': 'new'}),
        );
        dio.interceptors.add(
          AuthInterceptor(tokenStorage: tokens, dio: dio, refreshDio: refresh),
        );
        dio.httpClientAdapter = FakeAdapter(
          (_) => jsonBody({
            'message': 'failed',
          }, status: ++calls == 1 ? 401 : status),
        );
        await expectLater(
          dio
              .get<Object?>('/api/v1/documents')
              .timeout(const Duration(seconds: 2)),
          throwsA(isA<DioException>()),
        );
        expect(calls, 2);
        expect(tokens.accessToken, status == 401 ? isNull : 'new');
      }
    },
  );
}
