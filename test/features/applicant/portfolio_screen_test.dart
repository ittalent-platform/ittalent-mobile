import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/applicant/portfolio/portfolio_screen.dart';
import 'package:ittalent_mobile/features/applicant/portfolio/widgets/portfolio_form_sheet.dart';

import '../../helpers/fake_api.dart';

// Tall and wide: the sheet is long and untranslated keys render long in the test font.
const _size = Size(900, 1400);

Map<String, dynamic> _link(String id, String title, {String? description}) => {
  'id': id,
  'title': title,
  'url': 'https://me.example/$id',
  'description': description,
  'version': 1,
};

Map<String, dynamic> _page(
  List<Map<String, dynamic>> items, {
  int page = 1,
  int totalPages = 1,
}) => {
  'items': items,
  'page': page,
  'limit': 20,
  'total': items.length,
  'totalPages': totalPages,
};

Future<FakeAdapter> _open(
  WidgetTester tester, {
  List<Map<String, dynamic>>? items,
  ResponseBody Function(RequestOptions)? onWrite,
}) async {
  final adapter = FakeAdapter(
    (options) => options.method == 'GET'
        ? jsonBody(_page(items ?? [_link('p1', 'My site')]))
        : (onWrite ?? (_) => jsonBody(_link('p9', 'New')))(options),
  );
  await pumpWithApi(tester, adapter, const PortfolioScreen(), size: _size);
  return adapter;
}

// The page behind the sheet has no text fields, so every field belongs to the form.
Finder _fields() => find.byType(TextField);

Future<void> _fillAdd(WidgetTester tester) async {
  await tester.tap(find.byTooltip('portfolio.add'));
  await tester.pumpAndSettle();
  await tester.enterText(_fields().at(0), '  My new site ');
  await tester.enterText(_fields().at(1), 'https://new.example/work');
}

void main() {
  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
  });

  group('validatePortfolio', () {
    test('accepts a titled link with a web address', () {
      expect(
        validatePortfolio(title: 'Site', url: 'https://me.example').any,
        isFalse,
      );
    });

    test('rejects a blank title', () {
      expect(
        validatePortfolio(title: ' ', url: 'https://me.example').title,
        isNotNull,
      );
    });

    for (final url in const [
      'javascript:alert(1)',
      'data:text/html,x',
      'ftp://me.example',
      'https://user:pw@me.example',
      'https://localhost/x',
      'me.example',
      '',
    ]) {
      test('rejects the link "$url"', () {
        expect(validatePortfolio(title: 'Site', url: url).url, isNotNull);
      });
    }
  });

  testWidgets('lists the portfolio links', (tester) async {
    final adapter = await _open(
      tester,
      items: [_link('p1', 'My site', description: 'Projects')],
    );
    expect(adapter.requests.single.path, '/api/v1/me/portfolio-links');
    expect(find.text('My site'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the empty state with a way to add', (tester) async {
    await _open(tester, items: const []);
    expect(find.text('portfolio.empty.title'), findsOneWidget);
  });

  testWidgets('shows a retryable error', (tester) async {
    var fail = true;
    final adapter = FakeAdapter(
      (_) => fail
          ? jsonBody({'message': 'Boom'}, status: 500)
          : jsonBody(_page([_link('p1', 'Recovered')])),
    );
    await pumpWithApi(tester, adapter, const PortfolioScreen(), size: _size);
    expect(find.text('portfolio.errors.loadTitle'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('portfolio.errors.retry'));
    await tester.pumpAndSettle();
    expect(find.text('Recovered'), findsOneWidget);
  });

  testWidgets('loads the next page when scrolled to the end', (tester) async {
    final adapter = FakeAdapter((options) {
      final page = options.queryParameters['page'] as int;
      return jsonBody(
        page == 1
            ? _page([
                for (var i = 0; i < 8; i++) _link('p1-$i', 'First $i'),
              ], totalPages: 2)
            : _page([_link('p2', 'Second page link')], page: 2, totalPages: 2),
      );
    });
    // A short screen, so the first page really needs scrolling.
    await pumpWithApi(
      tester,
      adapter,
      const PortfolioScreen(),
      size: const Size(900, 500),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(adapter.requests.last.queryParameters['page'], 2);
    expect(find.text('Second page link'), findsOneWidget);
  });

  group('add', () {
    testWidgets('creates with an idempotency key and refreshes the list', (
      tester,
    ) async {
      final adapter = await _open(tester);
      await _fillAdd(tester);
      await tester.tap(find.text('portfolio.form.add'));
      await tester.pumpAndSettle();

      final post = adapter.requests.singleWhere((r) => r.method == 'POST');
      expect(post.data, {
        'title': 'My new site',
        'url': 'https://new.example/work',
      });
      expect(
        post.headers['Idempotency-Key'],
        matches(RegExp(r'^[0-9a-f]{32}$')),
      );
      expect(adapter.requests.where((r) => r.method == 'GET').length, 2);
      expect(find.text('portfolio.toast.added'), findsOneWidget);
    });

    testWidgets('does not send an invalid form', (tester) async {
      final adapter = await _open(tester);
      await tester.tap(find.byTooltip('portfolio.add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('portfolio.form.add'));
      await tester.pumpAndSettle();

      expect(find.text('portfolio.form.errors.title'), findsOneWidget);
      expect(find.text('portfolio.form.errors.url'), findsOneWidget);
      expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
    });

    testWidgets('retries with the same idempotency key after a failure', (
      tester,
    ) async {
      var failures = 1;
      final adapter = await _open(
        tester,
        onWrite: (_) => failures-- > 0
            ? jsonBody({'message': 'Boom'}, status: 500)
            : jsonBody(_link('p9', 'New')),
      );
      await _fillAdd(tester);
      await tester.tap(find.text('portfolio.form.add'));
      await tester.pumpAndSettle();
      expect(find.text('Boom'), findsOneWidget);

      await tester.tap(find.text('portfolio.form.add'));
      await tester.pumpAndSettle();

      final posts = adapter.requests.where((r) => r.method == 'POST').toList();
      expect(posts.length, 2);
      expect(
        posts[0].headers['Idempotency-Key'],
        posts[1].headers['Idempotency-Key'],
      );
    });

    testWidgets('says the link was already added on a duplicate', (
      tester,
    ) async {
      await _open(
        tester,
        onWrite: (_) => jsonBody({
          'message': 'dup',
          'code': 'DUPLICATE_PORTFOLIO_URL',
        }, status: 409),
      );
      await _fillAdd(tester);
      await tester.tap(find.text('portfolio.form.add'));
      await tester.pumpAndSettle();

      expect(find.text('portfolio.form.errors.duplicate'), findsOneWidget);
    });
  });

  group('delete', () {
    Future<void> confirmDelete(WidgetTester tester) async {
      await tester.tap(find.byTooltip('portfolio.delete.confirm'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('portfolio.delete.confirm'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('deletes after confirmation with the loaded version', (
      tester,
    ) async {
      final adapter = await _open(
        tester,
        onWrite: (_) => ResponseBody.fromString('', 204),
      );
      await confirmDelete(tester);

      final delete = adapter.requests.singleWhere((r) => r.method == 'DELETE');
      expect(delete.path, '/api/v1/me/portfolio-links/p1');
      expect(delete.queryParameters, {'expectedVersion': 1});
      expect(find.text('portfolio.toast.deleted'), findsOneWidget);
      expect(adapter.requests.where((r) => r.method == 'GET').length, 2);
    });

    testWidgets('keeps the link when deletion is cancelled', (tester) async {
      final adapter = await _open(tester);
      await tester.tap(find.byTooltip('portfolio.delete.confirm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('portfolio.delete.keep'));
      await tester.pumpAndSettle();

      expect(adapter.requests.where((r) => r.method == 'DELETE'), isEmpty);
    });

    testWidgets('reloads and says so when it was already removed', (
      tester,
    ) async {
      final adapter = await _open(
        tester,
        onWrite: (_) => jsonBody({'message': 'gone'}, status: 404),
      );
      await confirmDelete(tester);

      expect(find.text('portfolio.toast.alreadyGone'), findsOneWidget);
      expect(adapter.requests.where((r) => r.method == 'GET').length, 2);
    });

    testWidgets('keeps the list and says so when the delete fails', (
      tester,
    ) async {
      final adapter = await _open(
        tester,
        onWrite: (_) => jsonBody({'message': 'Boom'}, status: 500),
      );
      await confirmDelete(tester);

      expect(find.text('portfolio.errors.deleteFailed'), findsOneWidget);
      expect(adapter.requests.where((r) => r.method == 'GET').length, 1);
    });
  });
}
