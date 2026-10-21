import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/applicant/certificates/certificates_providers.dart';
import 'package:ittalent_mobile/features/applicant/certificates/certificates_screen.dart';

import '../../helpers/fake_api.dart';

Map<String, dynamic> _cert(
  String id,
  String name, {
  String? expiryDate,
  bool suggested = false,
  String? url,
  int version = 1,
}) => {
  'id': id,
  'name': name,
  'url': url ?? 'https://www.cert.example/$id',
  'issuer': 'Amazon',
  'issuedDate': '2024-01-01',
  'expiryDate': expiryDate,
  'version': version,
  'suggested': suggested,
  'sentCount': 0,
};

Map<String, dynamic> _page(
  List<Map<String, dynamic>> items, {
  int page = 1,
  int totalPages = 1,
  int suggestedTotal = 0,
}) => {
  'items': items,
  'page': page,
  'limit': 20,
  'total': items.length,
  'totalPages': totalPages,
  'suggestedTotal': suggestedTotal,
};

// Wide because untranslated keys render long in the test font.
const _wide = Size(900, 800);

Future<ProviderContainer> _pump(WidgetTester tester, FakeAdapter adapter) =>
    pumpWithApi(tester, adapter, const CertificatesScreen(), size: _wide);

void main() {
  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
  });

  group('CertificatesQuery', () {
    test('sends only the criteria that are set', () {
      expect(const CertificatesQuery().toQueryParameters(page: 1), {
        'page': 1,
        'limit': 20,
      });
    });

    test('trims the keyword and serialises both filters', () {
      expect(
        const CertificatesQuery(
          search: ' aws ',
          suggested: false,
          validity: 'expired',
        ).toQueryParameters(page: 3),
        {
          'page': 3,
          'limit': 20,
          'search': 'aws',
          'suggested': 'false',
          'validity': 'expired',
        },
      );
    });

    test('isFiltered reflects any criterion', () {
      expect(const CertificatesQuery().isFiltered, isFalse);
      expect(const CertificatesQuery(suggested: true).isFiltered, isTrue);
      expect(const CertificatesQuery(validity: 'valid').isFiltered, isTrue);
    });
  });

  test('CertificateLink knows whether it expired', () {
    final now = DateTime.utc(2026, 10, 21);
    expect(
      CertificateLink.fromJson(_cert('a', 'A', expiryDate: '2026-10-20'))
          .isExpired(now),
      isTrue,
    );
    expect(
      CertificateLink.fromJson(_cert('a', 'A', expiryDate: '2026-10-21'))
          .isExpired(now),
      isFalse,
    );
    expect(CertificateLink.fromJson(_cert('a', 'A')).isExpired(now), isFalse);
  });

  group('CertificatesScreen', () {
    testWidgets('lists the certificates from the API', (tester) async {
      final adapter = FakeAdapter(
        (_) => jsonBody(
          _page([
            _cert('c1', 'AWS Solutions Architect', suggested: true),
            _cert('c2', 'Scrum Master', expiryDate: '2000-01-01'),
          ]),
        ),
      );
      await _pump(tester, adapter);

      expect(adapter.requests.single.path, '/api/v1/me/certificate-links');
      expect(find.text('AWS Solutions Architect'), findsOneWidget);
      expect(find.text('Scrum Master'), findsOneWidget);
      expect(find.text('cert.example'), findsNWidgets(2));
      expect(find.text('certificates.suggestWhenApply'), findsNWidgets(2));
      expect(find.text('certificates.expired'), findsOneWidget);
      expect(find.text('certificates.notHttps'), findsNothing);
      final switches = tester.widgetList<Switch>(find.byType(Switch));
      expect(switches.map((s) => s.value), [true, false]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the empty state for a Candidate with none', (
      tester,
    ) async {
      await _pump(tester, FakeAdapter((_) => jsonBody(_page(const []))));
      expect(find.text('certificates.empty.title'), findsOneWidget);
    });

    testWidgets('shows a retryable error', (tester) async {
      var fail = true;
      final adapter = FakeAdapter(
        (_) => fail
            ? jsonBody({'message': 'Boom'}, status: 500)
            : jsonBody(_page([_cert('c1', 'Recovered')])),
      );
      await _pump(tester, adapter);
      expect(find.text('certificates.errors.loadTitle'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('certificates.errors.retry'));
      await tester.pumpAndSettle();
      expect(find.text('Recovered'), findsOneWidget);
    });

    testWidgets('searches on the server after the debounce, trimmed', (
      tester,
    ) async {
      final adapter = FakeAdapter(
        (options) => jsonBody(
          options.queryParameters.containsKey('search')
              ? _page([_cert('c1', 'AWS')])
              : _page([_cert('c1', 'AWS'), _cert('c2', 'Scrum')]),
        ),
      );
      await _pump(tester, adapter);

      await tester.enterText(find.byType(TextField), '  aws ');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(adapter.requests.last.queryParameters['search'], 'aws');
      expect(find.text('Scrum'), findsNothing);
    });

    testWidgets('applies the suggested and validity pills server-side', (
      tester,
    ) async {
      final adapter = FakeAdapter((_) => jsonBody(_page([_cert('c1', 'X')])));
      await _pump(tester, adapter);

      await tester.tap(find.byKey(const Key('certificates_filter_suggested')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('certificates.filter.yes').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('certificates_filter_validity')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('certificates.expired').last);
      await tester.pumpAndSettle();

      var params = adapter.requests.last.queryParameters;
      expect(params['suggested'], 'true');
      expect(params['validity'], 'expired');

      await tester.tap(find.byKey(const Key('certificates_filter_suggested')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('certificates.filter.all').last);
      await tester.pumpAndSettle();
      params = adapter.requests.last.queryParameters;
      expect(params.containsKey('suggested'), isFalse);
      expect(params['validity'], 'expired');
    });

    testWidgets('tags an http link as not HTTPS', (tester) async {
      await _pump(
        tester,
        FakeAdapter(
          (_) => jsonBody(
            _page([_cert('c1', 'IELTS', url: 'http://ielts.example/x')]),
          ),
        ),
      );
      expect(find.text('certificates.notHttps'), findsOneWidget);
    });

    testWidgets('the switch PATCHes suggested at once and Undo reverts it', (
      tester,
    ) async {
      final adapter = FakeAdapter((options) {
        if (options.method == 'PATCH') {
          final body = options.data as Map<String, dynamic>;
          return jsonBody(
            _cert(
              'c1',
              'AWS',
              suggested: body['suggested'] as bool,
              version: (body['expectedVersion'] as int) + 1,
            ),
          );
        }
        return jsonBody(_page([_cert('c1', 'AWS')]));
      });
      await _pump(tester, adapter);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final patch = adapter.requests.last;
      expect(patch.method, 'PATCH');
      expect(patch.path, '/api/v1/me/certificate-links/c1');
      expect(patch.data, {'expectedVersion': 1, 'suggested': true});
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(find.text('certificates.toast.suggested'), findsOneWidget);

      await tester.tap(find.text('certificates.toast.undo'));
      await tester.pumpAndSettle();
      expect(adapter.requests.last.data, {
        'expectedVersion': 2,
        'suggested': false,
      });
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });

    testWidgets('a 409 on the switch offers to load the latest', (
      tester,
    ) async {
      final adapter = FakeAdapter(
        (options) => options.method == 'PATCH'
            ? jsonBody({'code': 'VERSION_CONFLICT'}, status: 409)
            : jsonBody(_page([_cert('c1', 'AWS')])),
      );
      await _pump(tester, adapter);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(find.text('certificates.conflict.title'), findsOneWidget);

      final before = adapter.requests.length;
      await tester.tap(find.text('certificates.conflict.loadLatest'));
      await tester.pumpAndSettle();
      expect(adapter.requests.length, before + 1);
      expect(adapter.requests.last.method, 'GET');
    });

    testWidgets('the ⋯ menu shows the domain and version', (tester) async {
      await _pump(
        tester,
        FakeAdapter((_) => jsonBody(_page([_cert('c1', 'AWS', version: 2)]))),
      );
      await tester.tap(find.byTooltip('certificates.moreFor'));
      await tester.pumpAndSettle();
      expect(find.text('certificates.openLink'), findsOneWidget);
      expect(find.textContaining('cert.example · '), findsOneWidget);
    });

    testWidgets('rejects a blank keyword without a request', (tester) async {
      final adapter = FakeAdapter((_) => jsonBody(_page([_cert('c1', 'X')])));
      await _pump(tester, adapter);
      final before = adapter.requests.length;

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('applications.errors.keywordBlank'), findsOneWidget);
      expect(adapter.requests.length, before);
    });

    testWidgets('loads the next page when scrolled to the end', (tester) async {
      final adapter = FakeAdapter((options) {
        final page = options.queryParameters['page'] as int;
        return jsonBody(
          page == 1
              ? _page([
                  for (var i = 0; i < 8; i++) _cert('p1-$i', 'First $i'),
                ], totalPages: 2)
              : _page(
                  [_cert('p2', 'Second page cert')],
                  page: 2,
                  totalPages: 2,
                ),
        );
      });
      await _pump(tester, adapter);

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(adapter.requests.last.queryParameters['page'], 2);
      expect(find.text('Second page cert'), findsOneWidget);
    });
  });
}
