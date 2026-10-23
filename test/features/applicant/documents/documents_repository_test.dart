import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_model.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_providers.dart';

import '../../../helpers/fake_api.dart';

import 'documents_test_data.dart';

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
}
