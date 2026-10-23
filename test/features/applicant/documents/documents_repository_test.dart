import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/api/api_error.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_files.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_model.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_constants.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_providers.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_repository.dart';

import '../../../api/token_refresh_interceptor_test.dart'
    show InMemoryTokenStorage;
import '../../../helpers/fake_api.dart';

Map<String, Object?> documentJson({
  String id = '507f1f77bcf86cd799439011',
  String type = 'cv',
  String name = 'Nguyễn Văn An.pdf',
  bool isDefault = false,
}) => {
  'id': id,
  'ownerId': '507f191e810c19729de860ea',
  'type': type,
  'fileUrl': 'https://storage.test/file',
  'fileName': name,
  'mimeType': 'application/pdf',
  'size': 350208,
  'isDefault': isDefault,
  'createdAt': '2026-10-22T03:00:00.000Z',
};
Map<String, Object?> pageJson(
  List<Map<String, Object?>> items, {
  int page = 1,
  int pages = 1,
}) => {
  'items': items,
  'page': page,
  'limit': 20,
  'total': 35,
  'totalPages': pages,
};
SelectedDocument selected(String extension, {int? size, Uint8List? bytes}) {
  final content =
      bytes ??
      Uint8List.fromList([
        ...DocumentConstants.signatures[extension] ?? [1],
        0,
        1,
        255,
      ]);
  return SelectedDocument(
    name: 'Nguyễn Văn An.$extension',
    size: size ?? content.length,
    readBytes: () async => content,
  );
}

class StreamingAdapter implements HttpClientAdapter {
  StreamingAdapter(this.handler);
  final Future<ResponseBody> Function(RequestOptions, Uint8List) handler;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = BytesBuilder();
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.add(chunk);
      }
    }
    return handler(options, bytes.takeBytes());
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'DTOs parse both types, byte size, ISO date, default and pagination',
    () {
      for (final type in DocumentType.values) {
        final item = DocumentDto.fromJson(
          documentJson(type: type.value, isDefault: true),
        );
        expect(item.type, type);
        expect(item.size, 350208);
        expect(item.createdAt.isUtc, true);
        expect(item.isDefault, true);
        expect(item.ownerId, '507f191e810c19729de860ea');
      }
      final page = DocumentsPage.fromJson(
        pageJson([documentJson()], page: 2, pages: 3),
      );
      expect(page.page, 2);
      expect(page.totalPages, 3);
      expect(page.total, 35);
      expect(page.limit, 20);
    },
  );
  test('All omits type, trims search, omits blank, bounds search', () {
    expect(
      const DocumentsQuery(search: '   ').parameters(1).containsKey('search'),
      false,
    );
    expect(const DocumentsQuery().parameters(1).containsKey('type'), false);
    expect(
      const DocumentsQuery(
        type: DocumentType.coverLetter,
        search: '  An  ',
      ).parameters(2),
      {
        'page': 2,
        'limit': 20,
        'sort_by': 'created_at',
        'sort_order': 'desc',
        'type': 'cover_letter',
        'search': 'An',
      },
    );
    expect(
      () => DocumentsQuery(search: 'a' * 101).parameters(1),
      throwsArgumentError,
    );
  });
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
  test('pagination deduplicates, retains pages on failure, stops at totalPages and resets filter', () async {
    var failMore = true;
    var calls = 0;
    final dio = Dio()
      ..httpClientAdapter = FakeAdapter((o) {
        calls++;
        final page = o.queryParameters['page'] as int;
        if (page == 2 && failMore) {
          return jsonBody({'message': 'fail'}, status: 502);
        }
        return jsonBody(
          pageJson(
            [documentJson(id: 'a'), if (page == 2) documentJson(id: 'b')],
            page: page,
            pages: 2,
          ),
        );
      });
    final c = ProviderContainer(
      overrides: [dioProvider.overrideWithValue(dio)],
    );
    addTearDown(c.dispose);
    final sub = c.listen(documentsProvider, (_, _) {});
    addTearDown(sub.close);
    await c.read(documentsProvider.future);
    await c.read(documentsProvider.notifier).loadMore();
    expect(c.read(documentsProvider).requireValue.result.items.length, 1);
    expect(c.read(documentsProvider).requireValue.moreError, isNotNull);
    failMore = false;
    await c.read(documentsProvider.notifier).loadMore();
    expect(
      c.read(documentsProvider).requireValue.result.items.map((e) => e.id),
      ['a', 'b'],
    );
    await c.read(documentsProvider.notifier).loadMore();
    expect(calls, 3);
    c
        .read(documentsQueryProvider.notifier)
        .update(const DocumentsQuery(type: DocumentType.coverLetter));
    await c.read(documentsProvider.future);
    expect(c.read(documentsProvider).requireValue.result.page, 1);
  });
  test(
    'late search response and late loadMore cannot overwrite new filter',
    () async {
      final pending = Completer<ResponseBody>();
      final more = Completer<ResponseBody>();
      final dio = Dio()
        ..httpClientAdapter = StreamingAdapter((o, b) async {
          if (o.queryParameters['search'] == 'old') return pending.future;
          if (o.queryParameters['page'] == 2) return more.future;
          return jsonBody(
            pageJson([
              documentJson(
                id: o.queryParameters['search'] as String? ?? 'first',
              ),
            ], pages: 2),
          );
        });
      final c = ProviderContainer(
        overrides: [dioProvider.overrideWithValue(dio)],
      );
      addTearDown(c.dispose);
      final sub = c.listen(documentsProvider, (_, _) {});
      addTearDown(sub.close);
      await c.read(documentsProvider.future);
      final loadingMore = c.read(documentsProvider.notifier).loadMore();
      c
          .read(documentsQueryProvider.notifier)
          .update(const DocumentsQuery(search: 'old'));
      final oldFuture = c.read(documentsProvider.future);
      unawaited(
        oldFuture.catchError(
          (_) => const DocumentsList(
            DocumentsPage(
              items: [],
              page: 1,
              limit: 20,
              total: 0,
              totalPages: 0,
            ),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      c
          .read(documentsQueryProvider.notifier)
          .update(const DocumentsQuery(search: 'new'));
      await c.read(documentsProvider.future);
      more.complete(
        jsonBody(pageJson([documentJson(id: 'stale-more')], page: 2)),
      );
      pending.complete(jsonBody(pageJson([documentJson(id: 'old')])));
      await loadingMore;
      await Future<void>.delayed(Duration.zero);
      expect(
        c.read(documentsProvider).requireValue.result.items.single.id,
        'new',
      );
    },
  );
  for (final multipart in [false, true]) {
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
        } else {
          final result = await repo.download(
            DocumentDto.fromJson(documentJson()),
            cancelToken: cancel,
          );
          expect(result.bytes, [0, 255, 1]);
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
