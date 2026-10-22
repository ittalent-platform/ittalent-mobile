import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/components/common/company_avatar.dart';
import 'package:ittalent_mobile/features/applicant/applications/applications_constants.dart';
import 'package:ittalent_mobile/features/applicant/applications/applications_providers.dart';
import 'package:ittalent_mobile/features/applicant/applications/applications_screen.dart';

import '../../helpers/fake_api.dart';

Map<String, dynamic> _app(
  String id,
  String title, {
  String status = 'submitted',
  String company = 'FPT Software',
  bool canApplyAgain = false,
  String? withdrawnAt,
}) => {
  'id': id,
  'status': status,
  'canWithdraw': true,
  'canApplyAgain': canApplyAgain,
  'submittedAt': '2026-10-01T08:00:00.000Z',
  'latestStatusAt': '2026-10-03T08:00:00.000Z',
  'withdrawnAt': withdrawnAt,
  'job': {
    'title': title,
    'companyName': company,
    'location': 'Da Nang, Vietnam',
  },
};

Map<String, dynamic> _page(
  List<Map<String, dynamic>> items, {
  int page = 1,
  int totalPages = 1,
  Map<String, int>? statusCounts,
}) => {
  'items': items,
  'page': page,
  'limit': 20,
  'total': items.length,
  'totalPages': totalPages,
  'statusCounts': statusCounts ?? {'submitted': items.length},
};

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeAdapter adapter, {
  Size size = const Size(390, 844),
}) => pumpWithApi(tester, adapter, const ApplicationsScreen(), size: size);

void main() {
  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
  });

  group('ApplicationsQuery', () {
    test('sends only the criteria that are set', () {
      expect(const ApplicationsQuery().toQueryParameters(page: 1), {
        'page': 1,
        'limit': 20,
        'sortBy': 'submittedAt',
        'sortOrder': 'desc',
      });
    });

    test('trims the keyword and joins statuses, stage and dates', () {
      final params = ApplicationsQuery(
        search: '  flutter ',
        statuses: const {'submitted', 'under_review'},
        reviewStage: 'screening',
        submittedFrom: DateTime(2026, 10, 1),
        submittedTo: DateTime(2026, 10, 7),
        sortOrder: 'asc',
      ).toQueryParameters(page: 2);
      expect(params['page'], 2);
      expect(params['search'], 'flutter');
      expect(params['status'], 'submitted,under_review');
      expect(params['reviewStage'], 'screening');
      expect(params['sortOrder'], 'asc');
      expect(
        DateTime.parse(params['submittedFrom'] as String).toLocal(),
        DateTime(2026, 10, 1),
      );
      expect(
        DateTime.parse(params['submittedTo'] as String).toLocal(),
        DateTime(2026, 10, 7, 23, 59, 59, 999),
      );
    });

    test('submitted presets count back from today', () {
      final now = DateTime(2026, 10, 21, 15, 30);
      expect(
        ApplicationConstants.presetStart('7d', now),
        DateTime(2026, 10, 14),
      );
      expect(
        ApplicationConstants.presetStart('30d', now),
        DateTime(2026, 9, 21),
      );
      expect(
        ApplicationConstants.presetStart('3m', now),
        DateTime(2026, 7, 21),
      );
      expect(ApplicationConstants.presetOf(DateTime(2026, 9, 21), now), '30d');
      expect(ApplicationConstants.presetOf(DateTime(2026, 9, 20), now), isNull);
    });

    test('isFiltered ignores sort order', () {
      expect(const ApplicationsQuery(sortOrder: 'asc').isFiltered, isFalse);
      expect(const ApplicationsQuery(search: 'x').isFiltered, isTrue);
    });
  });

  test('company initials follow words or capitals', () {
    expect(CompanyAvatar.initials('CloudBridge'), 'CB');
    expect(CompanyAvatar.initials('Pixel Labs'), 'PL');
    expect(CompanyAvatar.initials('acme'), 'AC');
    expect(CompanyAvatar.initials('  '), '?');
  });

  test('ApplicationItem parses the API summary', () {
    final item = ApplicationItem.fromJson(_app('a1', 'Flutter Dev'));
    expect(item.jobTitle, 'Flutter Dev');
    expect(item.companyName, 'FPT Software');
    expect(item.canWithdraw, isTrue);
    expect(item.submittedAt, DateTime.utc(2026, 10, 1, 8));
    expect(item.latestStatusAt, DateTime.utc(2026, 10, 3, 8));
    expect(item.withdrawnAt, isNull);
  });

  group('ApplicationsScreen', () {
    for (final size in const [Size(360, 800), Size(390, 844)]) {
      testWidgets('renders the list without overflow at ${size.width}px', (
        tester,
      ) async {
        final adapter = FakeAdapter(
          (_) => jsonBody(
            _page([
              _app('a1', 'Senior Flutter Developer', status: 'interviewing'),
              _app('a2', 'Full-Stack TypeScript Engineer with a Long Title'),
            ]),
          ),
        );
        await _pump(tester, adapter, size: size);

        expect(find.text('Senior Flutter Developer'), findsOneWidget);
        expect(find.text('FS'), findsNWidgets(2));
        expect(
          find.text(
            'applications.subtitle_other applications.acrossCompanies_one',
          ),
          findsOneWidget,
        );
        expect(find.text('applications.status.interviewing'), findsOneWidget);
        expect(adapter.requests.single.path, '/api/v1/me/applications');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('shows the empty state when there are no applications', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeAdapter((_) => jsonBody(_page(const []))),
        size: const Size(900, 800),
      );
      expect(find.text('applications.noApplications'), findsOneWidget);
      expect(find.text('applications.browse'), findsOneWidget);
    });

    testWidgets('offered cards call for a reply; withdrawn cards say when', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeAdapter(
          (_) => jsonBody(
            _page([
              _app('a1', 'DevOps', status: 'offered', company: 'Pixel Labs'),
              _app(
                'a2',
                'Analyst',
                status: 'withdrawn',
                canApplyAgain: true,
                withdrawnAt: '2026-10-02T08:00:00.000Z',
              ),
            ]),
          ),
        ),
      );
      expect(find.text('applications.card.offer'), findsOneWidget);
      expect(
        find.text('applications.card.withdrawn · applications.card.applyAgain'),
        findsOneWidget,
      );
      expect(
        find.text('applications.card.submitted · applications.card.updated'),
        findsOneWidget,
      );
    });

    testWidgets('both pills open one sheet; status and preset apply', (
      tester,
    ) async {
      final adapter = FakeAdapter(
        (_) => jsonBody(
          _page(
            [_app('a1', 'Job')],
            statusCounts: {'submitted': 3, 'hired': 2, 'rejected': 1},
          ),
        ),
      );
      await _pump(tester, adapter, size: const Size(900, 1200));

      expect(
        find.text('applications.filter.status applications.filter.all'),
        findsOneWidget,
      );
      await tester.tap(
        find.text('applications.filter.submitted applications.range.any'),
      );
      await tester.pumpAndSettle();
      expect(find.text('applications.filter.title'), findsOneWidget);
      // Counts are fetched for the sheet: 3 + 2 + 1 with no status picked.
      expect(adapter.requests.last.queryParameters['limit'], 1);
      expect(
        find.text('applications.filter.showResults_other'),
        findsOneWidget,
      );

      await tester.tap(find.text('applications.status.hired'));
      await tester.tap(find.text('applications.range.7d'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('applications.filter.showResults_other'));
      await tester.pumpAndSettle();

      final params = adapter.requests.last.queryParameters;
      expect(params['status'], 'hired');
      final now = DateTime.now();
      expect(
        DateTime.parse(params['submittedFrom'] as String).toLocal(),
        DateTime(now.year, now.month, now.day - 7),
      );
      expect(
        find.text('applications.filter.status applications.status.hired'),
        findsOneWidget,
      );
      expect(find.text('applications.range.7d'), findsOneWidget);
    });

    testWidgets('reset in the sheet clears status and date', (tester) async {
      final adapter = FakeAdapter((_) => jsonBody(_page([_app('a1', 'Job')])));
      final container = await _pump(
        tester,
        adapter,
        size: const Size(900, 1200),
      );
      container
          .read(applicationsQueryProvider.notifier)
          .update(const ApplicationsQuery(statuses: {'hired'}));
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('applications.filter.status applications.status.hired'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('applications.filter.reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('applications.filter.showResults_one'));
      await tester.pumpAndSettle();

      expect(container.read(applicationsQueryProvider).isFiltered, isFalse);
    });

    testWidgets('shows a retryable error and never fake data', (tester) async {
      var fail = true;
      final adapter = FakeAdapter(
        (_) => fail
            ? jsonBody({'message': 'Boom'}, status: 500)
            : jsonBody(_page([_app('a1', 'Recovered job')])),
      );
      await _pump(tester, adapter);

      expect(find.text('applications.loadErrorTitle'), findsOneWidget);
      expect(find.text('Boom'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('applications.retry'));
      await tester.pumpAndSettle();
      expect(find.text('Recovered job'), findsOneWidget);
    });

    testWidgets('searches on the server after the debounce, trimmed', (
      tester,
    ) async {
      final adapter = FakeAdapter((options) {
        final search = options.queryParameters['search'];
        return jsonBody(
          search == null
              ? _page([_app('a1', 'Flutter Dev'), _app('a2', 'Java Dev')])
              : _page([_app('a1', 'Flutter Dev')]),
        );
      });
      await _pump(tester, adapter);

      await tester.enterText(find.byType(TextField), '  flutter ');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(adapter.requests.last.queryParameters['search'], 'flutter');
      expect(find.text('Java Dev'), findsNothing);
      expect(find.text('Flutter Dev'), findsOneWidget);
    });

    testWidgets('rejects a blank keyword without a request', (tester) async {
      final adapter = FakeAdapter((_) => jsonBody(_page([_app('a1', 'Job')])));
      await _pump(tester, adapter);
      final before = adapter.requests.length;

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('applications.errors.keywordBlank'), findsOneWidget);
      expect(adapter.requests.length, before);
    });

    testWidgets('shows no-match state with a way to clear the search', (
      tester,
    ) async {
      final adapter = FakeAdapter(
        (options) => jsonBody(
          options.queryParameters.containsKey('search')
              ? _page(const [])
              : _page([_app('a1', 'Job')]),
        ),
      );
      // Untranslated keys are long, so give the action button room.
      await _pump(tester, adapter, size: const Size(900, 800));

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('applications.noMatches'), findsOneWidget);

      await tester.tap(find.text('applications.clearFilters'));
      await tester.pumpAndSettle();
      expect(find.text('Job'), findsOneWidget);
    });

    testWidgets('loads the next page when scrolled to the end', (tester) async {
      final adapter = FakeAdapter((options) {
        final page = options.queryParameters['page'] as int;
        return jsonBody(
          page == 1
              ? _page([
                  for (var i = 0; i < 8; i++) _app('p1-$i', 'First page $i'),
                ], totalPages: 2)
              : _page(
                  [_app('p2-0', 'Second page job')],
                  page: 2,
                  totalPages: 2,
                ),
        );
      });
      await _pump(tester, adapter);

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(adapter.requests.last.queryParameters['page'], 2);
      expect(find.text('Second page job'), findsOneWidget);
    });
  });
}
