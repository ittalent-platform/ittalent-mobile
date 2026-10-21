import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/applicant/applications/application_detail_screen.dart';
import 'package:ittalent_mobile/features/applicant/applications/application_history_screen.dart';

import '../../helpers/fake_api.dart';

const _id = '507f1f77bcf86cd799439011';
// Tall enough that the lazy list builds every card.
const _tall = Size(390, 2400);

Map<String, dynamic> _detail({
  String status = 'under_review',
  String? withdrawalReason,
}) => {
  'id': _id,
  'status': status,
  'reviewStage': 'screening',
  'canWithdraw': true,
  'version': 2,
  'message': 'I would love to join.',
  'withdrawalReason': withdrawalReason,
  'submittedAt': '2026-10-01T08:00:00.000Z',
  'latestStatusAt': '2026-10-03T08:00:00.000Z',
  'job': {
    'title': 'Senior Flutter Developer',
    'companyName': 'FPT Software',
    'location': 'Da Nang, Vietnam',
  },
  'attachments': [
    {'documentId': 'd1', 'type': 'cv', 'fileName': 'my-cv.pdf'},
  ],
  'certificates': [
    {
      'id': 'c1',
      'version': 1,
      'name': 'AWS Solutions Architect',
      'url': 'https://cert.example/aws',
      'issuer': 'Amazon',
      'issuedDate': '2024-01-01',
      'expiryDate': null,
    },
  ],
};

void main() {
  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
  });

  group('ApplicationDetailScreen', () {
    testWidgets('shows the submitted snapshot and how it was sent', (
      tester,
    ) async {
      final adapter = FakeAdapter((_) => jsonBody(_detail()));
      await pumpWithApi(
        tester,
        adapter,
        const ApplicationDetailScreen(applicationId: _id),
        size: _tall,
      );

      expect(adapter.requests.single.path, '/api/v1/me/applications/$_id');
      expect(find.text('Senior Flutter Developer'), findsOneWidget);
      expect(find.text('FS'), findsOneWidget);
      expect(find.text('applications.status.under_review'), findsOneWidget);
      // Step 2 of 5, next is Interviewing.
      expect(find.text('2'), findsOneWidget);
      expect(
        find.text('applications.stepOf · applications.nextStatus'),
        findsOneWidget,
      );
      expect(find.textContaining('applications.updates_other'), findsOneWidget);
      expect(find.textContaining('APP-9011'), findsOneWidget);
      expect(find.text('applications.withdrawnReason'), findsNothing);

      // What was sent sits behind "Documents sent".
      await tester.tap(find.text('applications.documentsSent'));
      await tester.pumpAndSettle();
      expect(find.textContaining('my-cv.pdf'), findsOneWidget);
      expect(find.text('AWS Solutions Architect'), findsOneWidget);
      expect(find.text('I would love to join.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the ⋯ menu opens the job as saved when applying', (
      tester,
    ) async {
      final adapter = FakeAdapter((_) => jsonBody(_detail()));
      await pumpWithApi(
        tester,
        adapter,
        const ApplicationDetailScreen(applicationId: _id),
        size: _tall,
      );

      await tester.tap(find.byTooltip('applications.moreActions'));
      await tester.pumpAndSettle();
      expect(find.text('applications.cancel'), findsOneWidget);
      await tester.tap(find.text('applications.viewJob'));
      await tester.pumpAndSettle();
      expect(find.text('applications.jobSnapshotDescription'), findsOneWidget);
    });

    testWidgets('an ended application shows no step progress', (tester) async {
      final adapter = FakeAdapter((_) => jsonBody(_detail(status: 'rejected')));
      await pumpWithApi(
        tester,
        adapter,
        const ApplicationDetailScreen(applicationId: _id),
        size: _tall,
      );
      expect(find.text('applications.next.rejected'), findsOneWidget);
      expect(find.textContaining('applications.stepOf'), findsNothing);
    });

    testWidgets('shows the withdrawal reason of a withdrawn application', (
      tester,
    ) async {
      final adapter = FakeAdapter(
        (_) => jsonBody(
          _detail(status: 'withdrawn', withdrawalReason: 'Took another offer'),
        ),
      );
      await pumpWithApi(
        tester,
        adapter,
        const ApplicationDetailScreen(applicationId: _id),
        size: _tall,
      );
      expect(find.text('applications.withdrawnReason'), findsOneWidget);
    });

    testWidgets('treats a foreign or unknown id as not found', (tester) async {
      final adapter = FakeAdapter(
        (_) => jsonBody({'message': 'Application not found'}, status: 404),
      );
      await pumpWithApi(
        tester,
        adapter,
        const ApplicationDetailScreen(applicationId: _id),
      );
      expect(find.text('applications.notFound'), findsOneWidget);
    });

    testWidgets('offers a retry after a server failure', (tester) async {
      var fail = true;
      final adapter = FakeAdapter(
        (_) => fail
            ? jsonBody({'message': 'Boom'}, status: 500)
            : jsonBody(_detail()),
      );
      await pumpWithApi(
        tester,
        adapter,
        const ApplicationDetailScreen(applicationId: _id),
      );
      expect(find.text('Boom'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('applications.retry'));
      await tester.pumpAndSettle();
      expect(find.text('Senior Flutter Developer'), findsOneWidget);
    });
  });

  group('ApplicationHistoryScreen', () {
    testWidgets('lists the entries in order with the public actor role', (
      tester,
    ) async {
      final adapter = FakeAdapter(
        (_) => jsonBody({
          'items': [
            {
              'status': 'submitted',
              'actorRole': 'candidate',
              'occurredAt': '2026-10-01T08:00:00.000Z',
            },
            {
              'status': 'under_review',
              'reviewStage': 'screening',
              'actorRole': 'company',
              'occurredAt': '2026-10-02T08:00:00.000Z',
            },
          ],
          'page': 1,
          'totalPages': 1,
        }),
      );
      await pumpWithApi(
        tester,
        adapter,
        const ApplicationHistoryScreen(applicationId: _id),
      );

      expect(
        adapter.requests.single.path,
        '/api/v1/me/applications/$_id/history',
      );
      expect(find.text('applications.history.submitted'), findsOneWidget);
      expect(
        find.text(
          'applications.history.under_review · applications.stage.screening',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('applications.by.company'), findsOneWidget);
      // Newest first.
      expect(
        tester.getTopLeft(find.text('applications.history.submitted')).dy,
        greaterThan(
          tester
              .getTopLeft(find.textContaining('applications.history.under'))
              .dy,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('reads every page of a long history', (tester) async {
      final adapter = FakeAdapter((options) {
        final page = options.queryParameters['page'] as int;
        return jsonBody({
          'items': [
            {
              'status': page == 1 ? 'submitted' : 'withdrawn',
              'actorRole': 'candidate',
              'occurredAt': '2026-10-0${page}T08:00:00.000Z',
            },
          ],
          'page': page,
          'totalPages': 2,
        });
      });
      await pumpWithApi(
        tester,
        adapter,
        const ApplicationHistoryScreen(applicationId: _id),
      );

      expect(adapter.requests.length, 2);
      expect(find.text('applications.history.withdrawn'), findsOneWidget);
    });

    testWidgets('shows an empty state when there is no history', (
      tester,
    ) async {
      final adapter = FakeAdapter(
        (_) => jsonBody({'items': <Object>[], 'page': 1, 'totalPages': 0}),
      );
      await pumpWithApi(
        tester,
        adapter,
        const ApplicationHistoryScreen(applicationId: _id),
      );
      expect(find.text('applications.noHistory'), findsOneWidget);
    });
  });
}
