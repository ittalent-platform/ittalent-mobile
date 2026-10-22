import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/applicant/certificates/certificates_screen.dart';
import 'package:ittalent_mobile/features/applicant/certificates/widgets/certificate_form_page.dart';

import '../../helpers/fake_api.dart';

// Tall and wide: the sheet is long and untranslated keys render long in the test font.
const _size = Size(900, 1600);

Map<String, dynamic> _cert({
  String? issuer = 'Amazon',
  int version = 2,
  int sentCount = 0,
  bool suggested = false,
}) => {
  'id': 'c1',
  'name': 'AWS Architect',
  'url': 'https://cert.example/aws',
  'issuer': issuer,
  'issuedDate': '2024-01-01',
  'expiryDate': null,
  'version': version,
  'suggested': suggested,
  'sentCount': sentCount,
  'updatedAt': '2026-10-01T08:00:00.000Z',
};

Map<String, dynamic> _list(List<Map<String, dynamic>> items) => {
  'items': items,
  'page': 1,
  'limit': 20,
  'total': items.length,
  'totalPages': 1,
  'suggestedTotal': 0,
};

Future<FakeAdapter> _open(
  WidgetTester tester, {
  List<Map<String, dynamic>>? items,
  ResponseBody Function(RequestOptions)? onWrite,
}) async {
  final adapter = FakeAdapter(
    (options) => options.method == 'GET'
        ? jsonBody(_list(items ?? [_cert()]))
        : (onWrite ?? (_) => jsonBody(_cert()))(options),
  );
  await pumpWithApi(tester, adapter, const CertificatesScreen(), size: _size);
  return adapter;
}

// The list's own search box sits behind the page, so only look inside the page.
Finder _formFields() => find.descendant(
  of: find.byType(CertificateFormPage),
  matching: find.byType(TextField),
);

Future<void> _menu(WidgetTester tester, String item) async {
  await tester.tap(find.byTooltip('certificates.moreFor'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item));
  await tester.pumpAndSettle();
}

Future<void> _fillAdd(WidgetTester tester) async {
  await tester.tap(find.byTooltip('certificates.add'));
  await tester.pumpAndSettle();
  final fields = _formFields();
  await tester.enterText(fields.at(0), '  Scrum Master ');
  await tester.enterText(fields.at(1), 'https://scrum.example/psm');
}

void main() {
  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
  });

  group('validateCertificate', () {
    CertificateFormErrors check({
      String name = 'AWS',
      String url = 'https://cert.example/a',
      String? issued,
      String? expiry,
    }) => validateCertificate(
      name: name,
      url: url,
      issuedDate: issued,
      expiryDate: expiry,
    );

    test('accepts a named certificate with an https link', () {
      expect(check().any, isFalse);
    });

    test('requires https unless the saved http link is unchanged', () {
      expect(check(url: 'http://cert.example/a').url, isNotNull);
      expect(
        validateCertificate(
          name: 'AWS',
          url: 'http://cert.example/a',
          requireHttps: false,
        ).any,
        isFalse,
      );
    });

    test('rejects a blank name', () {
      expect(check(name: '  ').name, isNotNull);
    });

    for (final url in const [
      'http://cert.example/a',
      'ftp://cert.example/a',
      'javascript:alert(1)',
      'https://localhost/a',
      'https://user:pw@cert.example/a',
      'cert.example/a',
      '',
    ]) {
      test('rejects the link "$url"', () {
        expect(check(url: url).url, isNotNull);
      });
    }

    test('requires the expiry not to precede the issued date', () {
      expect(
        check(issued: '2024-05-01', expiry: '2024-04-30').dates,
        isNotNull,
      );
      expect(check(issued: '2024-05-01', expiry: '2024-05-01').dates, isNull);
      expect(check(expiry: '2020-01-01').dates, isNull);
    });
  });

  test('idempotency keys are unique and 32 hex characters', () {
    final a = newIdempotencyKey();
    expect(a, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(newIdempotencyKey(), isNot(a));
  });

  group('add', () {
    testWidgets('creates with an idempotency key and refreshes the list', (
      tester,
    ) async {
      final adapter = await _open(tester);
      await _fillAdd(tester);
      await tester.tap(find.text('certificates.form.add'));
      await tester.pumpAndSettle();

      final post = adapter.requests.singleWhere((r) => r.method == 'POST');
      expect(post.path, '/api/v1/me/certificate-links');
      expect(post.data, {
        'name': 'Scrum Master',
        'url': 'https://scrum.example/psm',
      });
      expect(
        post.headers['Idempotency-Key'],
        matches(RegExp(r'^[0-9a-f]{32}$')),
      );
      expect(adapter.requests.where((r) => r.method == 'GET').length, 2);
      expect(adapter.requests.where((r) => r.method == 'PATCH'), isEmpty);
      expect(find.byType(CertificateFormPage), findsNothing);
      expect(find.text('certificates.toast.added'), findsOneWidget);
    });

    testWidgets('switches on Suggest with a PATCH after creating', (
      tester,
    ) async {
      final adapter = await _open(
        tester,
        onWrite: (options) => jsonBody(
          options.method == 'POST'
              ? _cert(version: 1)
              : _cert(version: 2, suggested: true),
        ),
      );
      await _fillAdd(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(CertificateFormPage),
          matching: find.byType(Switch),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('certificates.form.add'));
      await tester.pumpAndSettle();

      final post = adapter.requests.singleWhere((r) => r.method == 'POST');
      expect((post.data as Map).containsKey('suggested'), isFalse);
      final patch = adapter.requests.singleWhere((r) => r.method == 'PATCH');
      expect(patch.data, {'expectedVersion': 1, 'suggested': true});
      expect(find.text('certificates.toast.added'), findsOneWidget);
    });

    testWidgets('does not send an invalid form and sums up the errors', (
      tester,
    ) async {
      final adapter = await _open(tester);
      await tester.tap(find.byTooltip('certificates.add'));
      await tester.pumpAndSettle();
      await tester.enterText(_formFields().at(1), 'http://cert.example/a');
      await tester.tap(find.text('certificates.form.add'));
      await tester.pumpAndSettle();

      expect(
        find.text('certificates.form.errors.summary_other'),
        findsOneWidget,
      );
      expect(find.text('certificates.form.errors.name'), findsOneWidget);
      expect(find.text('certificates.form.errors.url'), findsOneWidget);
      expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
    });

    testWidgets('"doesn\'t expire" hides the expiry date', (tester) async {
      await _open(tester);
      await tester.tap(find.byTooltip('certificates.add'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('certificate_form_expires')), findsOneWidget);

      await tester.tap(find.text('certificates.form.noExpiry'));
      await tester.pump();
      expect(find.byKey(const Key('certificate_form_expires')), findsNothing);
    });

    testWidgets('retries with the same idempotency key after a failure', (
      tester,
    ) async {
      var failures = 1;
      final adapter = await _open(
        tester,
        onWrite: (_) => failures-- > 0
            ? jsonBody({'message': 'Boom'}, status: 500)
            : jsonBody(_cert()),
      );
      await _fillAdd(tester);
      await tester.tap(find.text('certificates.form.add'));
      await tester.pumpAndSettle();
      expect(find.text('certificates.form.errors.saveFailed'), findsOneWidget);

      await tester.tap(find.text('certificates.form.add'));
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
          'code': 'DUPLICATE_CERTIFICATE_URL',
        }, status: 409),
      );
      await _fillAdd(tester);
      await tester.tap(find.text('certificates.form.add'));
      await tester.pumpAndSettle();

      expect(find.text('certificates.form.errors.duplicate'), findsOneWidget);
    });
  });

  group('edit and delete', () {
    testWidgets('sends only the changed field with the loaded version', (
      tester,
    ) async {
      final adapter = await _open(tester);
      await _menu(tester, 'certificates.edit');
      await tester.enterText(_formFields().at(0), 'AWS Architect Pro');
      await tester.tap(find.text('certificates.form.save'));
      await tester.pumpAndSettle();

      final patch = adapter.requests.singleWhere((r) => r.method == 'PATCH');
      expect(patch.path, '/api/v1/me/certificate-links/c1');
      expect(patch.data, {'expectedVersion': 2, 'name': 'AWS Architect Pro'});
      expect(find.text('certificates.toast.saved'), findsOneWidget);
    });

    testWidgets('clears an emptied optional field with null', (tester) async {
      final adapter = await _open(tester);
      await _menu(tester, 'certificates.edit');
      await tester.enterText(_formFields().at(2), '');
      await tester.tap(find.text('certificates.form.save'));
      await tester.pumpAndSettle();

      final patch = adapter.requests.singleWhere((r) => r.method == 'PATCH');
      expect(patch.data, {'expectedVersion': 2, 'issuer': null});
    });

    testWidgets('sends nothing when nothing changed', (tester) async {
      final adapter = await _open(tester);
      await _menu(tester, 'certificates.edit');
      expect(find.text('certificates.form.editDescription'), findsOneWidget);
      await tester.tap(find.text('certificates.form.save'));
      await tester.pumpAndSettle();

      expect(adapter.requests.where((r) => r.method == 'PATCH'), isEmpty);
    });

    testWidgets('reloads and says so when it changed elsewhere', (
      tester,
    ) async {
      final adapter = await _open(
        tester,
        onWrite: (_) => jsonBody({
          'message': 'stale',
          'code': 'VERSION_CONFLICT',
        }, status: 409),
      );
      await _menu(tester, 'certificates.edit');
      await tester.enterText(_formFields().at(0), 'Renamed');
      await tester.tap(find.text('certificates.form.save'));
      await tester.pumpAndSettle();

      expect(find.text('certificates.conflict.title'), findsOneWidget);
      await tester.tap(find.text('certificates.conflict.loadLatest'));
      await tester.pumpAndSettle();
      expect(find.byType(CertificateFormPage), findsNothing);
      expect(adapter.requests.where((r) => r.method == 'GET').length, 2);
    });

    testWidgets('says so when it was deleted elsewhere', (tester) async {
      await _open(
        tester,
        onWrite: (_) => jsonBody({'message': 'gone'}, status: 404),
      );
      await _menu(tester, 'certificates.edit');
      await tester.enterText(_formFields().at(0), 'Renamed');
      await tester.tap(find.text('certificates.form.save'));
      await tester.pumpAndSettle();

      expect(find.text('certificates.gone.title'), findsOneWidget);
      await tester.tap(find.text('certificates.gone.back'));
      await tester.pumpAndSettle();
      expect(find.byType(CertificateFormPage), findsNothing);
    });

    testWidgets('deletes after confirmation with the loaded version', (
      tester,
    ) async {
      final adapter = await _open(
        tester,
        items: [_cert(sentCount: 2)],
        onWrite: (_) => ResponseBody.fromString('', 204),
      );
      await _menu(tester, 'certificates.deleteMenu');
      expect(find.text('certificates.delete.title'), findsOneWidget);
      expect(find.text('certificates.delete.sentNote_other'), findsOneWidget);
      await tester.tap(find.text('certificates.delete.confirm'));
      await tester.pumpAndSettle();

      final delete = adapter.requests.singleWhere((r) => r.method == 'DELETE');
      expect(delete.path, '/api/v1/me/certificate-links/c1');
      expect(delete.queryParameters, {'expectedVersion': 2});
      expect(find.text('certificates.toast.deleted'), findsOneWidget);
    });

    testWidgets('keeps the certificate when deletion is cancelled', (
      tester,
    ) async {
      final adapter = await _open(tester);
      await _menu(tester, 'certificates.deleteMenu');
      expect(find.text('certificates.delete.sentNote_other'), findsNothing);
      await tester.tap(find.text('actions.cancel'));
      await tester.pumpAndSettle();

      expect(adapter.requests.where((r) => r.method == 'DELETE'), isEmpty);
    });
  });
}
