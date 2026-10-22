import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/components/ui/app_button.dart';
import 'package:ittalent_mobile/features/applicant/applications/application_detail_screen.dart';

import '../../helpers/fake_api.dart';

const _id = '507f1f77bcf86cd799439011';
// Tall so the lazy list builds every card; wide because untranslated keys render long in the test font.
const _tall = Size(900, 2400);

Map<String, dynamic> _detail({
  bool canWithdraw = true,
  String status = 'submitted',
}) => {
  'id': _id,
  'status': status,
  'canWithdraw': canWithdraw,
  'version': 3,
  'submittedAt': '2026-10-01T08:00:00.000Z',
  'job': {'title': 'Flutter Developer', 'companyName': 'FPT Software'},
  'attachments': <Object>[],
  'certificates': <Object>[],
};

Finder _withdrawButton() =>
    find.widgetWithText(AppButton, 'applications.withdraw');

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip('applications.moreActions'));
  await tester.pumpAndSettle();
}

Future<void> _openSheet(WidgetTester tester) async {
  await _openMenu(tester);
  await tester.tap(find.text('applications.withdrawEllipsis'));
  await tester.pumpAndSettle();
}

Future<FakeAdapter> _open(
  WidgetTester tester, {
  bool canWithdraw = true,
  ResponseBody Function()? onPatch,
  Map<String, dynamic> Function()? onGet,
}) async {
  final adapter = FakeAdapter(
    (options) => options.method == 'PATCH'
        ? (onPatch ?? () => jsonBody(_detail(canWithdraw: false)))()
        : jsonBody(onGet?.call() ?? _detail(canWithdraw: canWithdraw)),
  );
  await pumpWithApi(
    tester,
    adapter,
    const Scaffold(body: ApplicationDetailScreen(applicationId: _id)),
    size: _tall,
  );
  return adapter;
}

void main() {
  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
  });

  testWidgets('the ⋯ menu hides Withdraw when the server says no', (
    tester,
  ) async {
    await _open(tester, canWithdraw: false);
    await _openMenu(tester);
    expect(find.text('applications.viewJob'), findsOneWidget);
    expect(find.text('applications.withdrawEllipsis'), findsNothing);
  });

  testWidgets('the ⋯ menu offers Withdraw when it is allowed', (tester) async {
    await _open(tester);
    await _openMenu(tester);
    expect(find.text('applications.withdrawEllipsis'), findsOneWidget);
  });

  testWidgets('withdraws with the loaded version and a trimmed reason', (
    tester,
  ) async {
    final adapter = await _open(tester);
    await _openSheet(tester);

    await tester.enterText(find.byType(TextField), '  Took another offer ');
    await tester.tap(_withdrawButton());
    await tester.pumpAndSettle();

    final patch = adapter.requests.singleWhere((r) => r.method == 'PATCH');
    expect(patch.path, '/api/v1/me/applications/$_id/withdraw');
    expect(patch.data, {'expectedVersion': 3, 'reason': 'Took another offer'});
    expect(find.text('applications.toast.withdrawnOne'), findsOneWidget);
    // The detail is reloaded after the change.
    expect(adapter.requests.where((r) => r.method == 'GET').length, 2);
  });

  testWidgets('sends no reason when it is left empty', (tester) async {
    final adapter = await _open(tester);
    await _openSheet(tester);
    await tester.tap(_withdrawButton());
    await tester.pumpAndSettle();

    final patch = adapter.requests.singleWhere((r) => r.method == 'PATCH');
    expect(patch.data, {'expectedVersion': 3});
  });

  testWidgets('rejects a reason shorter than 5 characters without a request', (
    tester,
  ) async {
    final adapter = await _open(tester);
    await _openSheet(tester);

    await tester.enterText(find.byType(TextField), 'no');
    await tester.tap(_withdrawButton());
    await tester.pumpAndSettle();

    expect(find.text('applications.errors.reasonLength'), findsOneWidget);
    expect(adapter.requests.where((r) => r.method == 'PATCH'), isEmpty);
  });
  testWidgets('explains an already-decided status inline after reloading', (
    tester,
  ) async {
    var decided = false;
    final adapter = await _open(
      tester,
      onGet: () =>
          decided ? _detail(canWithdraw: false, status: 'rejected') : _detail(),
      onPatch: () {
        decided = true;
        return jsonBody({
          'message':
              'Only submitted or under-review applications can be withdrawn',
        }, status: 400);
      },
    );
    await _openSheet(tester);
    await tester.tap(_withdrawButton());
    await tester.pumpAndSettle();

    expect(find.text('applications.withdrawTitle'), findsOneWidget);
    expect(find.text('applications.alreadyDecided'), findsOneWidget);
    expect(_withdrawButton(), findsNothing);
    expect(adapter.requests.where((r) => r.method == 'GET').length, 2);
  });

  testWidgets('a stale version (409) retries with the reloaded one', (
    tester,
  ) async {
    var calls = 0;
    final adapter = await _open(
      tester,
      onPatch: () => ++calls == 1
          ? jsonBody({'message': 'Application changed'}, status: 409)
          : jsonBody(_detail(canWithdraw: false)),
    );
    await _openSheet(tester);
    await tester.tap(_withdrawButton());
    await tester.pumpAndSettle();
    expect(find.text('applications.withdrawConflict'), findsOneWidget);

    await tester.tap(_withdrawButton());
    await tester.pumpAndSettle();
    expect(adapter.requests.where((r) => r.method == 'PATCH').length, 2);
    expect(find.text('applications.toast.withdrawnOne'), findsOneWidget);
  });

  testWidgets('keeps the sheet open with the error when saving fails', (
    tester,
  ) async {
    await _open(
      tester,
      onPatch: () => jsonBody({'message': 'Boom'}, status: 500),
    );
    await _openSheet(tester);
    await tester.tap(_withdrawButton());
    await tester.pumpAndSettle();

    expect(find.text('Boom'), findsOneWidget);
    expect(find.text('applications.withdrawTitle'), findsOneWidget);
  });
}
