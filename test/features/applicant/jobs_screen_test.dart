import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/components/common/app_error_state.dart';
import 'package:ittalent_mobile/components/ui/app_badge.dart';
import 'package:ittalent_mobile/components/ui/app_button.dart';
import 'package:ittalent_mobile/features/applicant/jobs/jobs_constants.dart';
import 'package:ittalent_mobile/features/applicant/jobs/jobs_format.dart';
import 'package:ittalent_mobile/features/applicant/jobs/jobs_models.dart';
import 'package:ittalent_mobile/features/applicant/jobs/jobs_providers.dart';
import 'package:ittalent_mobile/features/applicant/jobs/jobs_screen.dart';
import 'package:ittalent_mobile/features/applicant/jobs/widgets/job_chip.dart';

import '../../helpers/fake_api.dart';

String _daysAgo(int days) =>
    DateTime.now().subtract(Duration(days: days)).toUtc().toIso8601String();

String _daysAhead(int days) =>
    DateTime.now().add(Duration(days: days)).toUtc().toIso8601String();

Map<String, dynamic> _job(
  String id,
  String title, {
  String company = 'Nimbus Pay',
  String? location = 'Ha Noi',
  String? type = 'Full-time',
  String? level = 'Senior',
  num? min = 45000000,
  num? max = 60000000,
  bool negotiable = false,
  String currency = 'VND',
  String? createdAt,
  String? expiresAt,
}) => {
  'id': id,
  'enterpriseId': 'e-$company',
  'enterprise': {'id': 'e-$company', 'name': company, 'logoUrl': null},
  'title': title,
  'location': location,
  'employmentType': type,
  'level': level,
  'salaryMin': min,
  'salaryMax': max,
  'salaryNegotiable': negotiable,
  'currency': currency,
  'openings': 2,
  'createdAt': createdAt ?? _daysAgo(3),
  'expiresAt': expiresAt ?? _daysAhead(20),
};

Map<String, dynamic> _page(
  List<Map<String, dynamic>> items, {
  int page = 1,
  int totalPages = 1,
  int? total,
}) => {
  'items': items,
  'page': page,
  'limit': 100,
  'total': total ?? items.length,
  'totalPages': totalPages,
};

JobPosting _posting({
  num? min = 45000000,
  num? max = 60000000,
  bool negotiable = false,
  String currency = 'VND',
}) => JobPosting.fromJson(
  _job(
    'j1',
    'Backend Engineer',
    min: min,
    max: max,
    negotiable: negotiable,
    currency: currency,
  ),
);

/// Serves each page of the list after a short wait, and notes which pages were
/// asked for and how many requests were in flight together.
class _CountingAdapter implements HttpClientAdapter {
  _CountingAdapter(this.pageBody);

  final Map<String, dynamic> Function(int page) pageBody;
  final List<int> pages = [];
  int mostAtOnce = 0;
  int _inFlight = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final page = options.queryParameters['page'] as int;
    pages.add(page);
    _inFlight++;
    if (_inFlight > mostAtOnce) mostAtOnce = _inFlight;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    _inFlight--;
    return jsonBody(pageBody(page));
  }

  @override
  void close({bool force = false}) {}
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeAdapter adapter, {
  Size size = const Size(390, 844),
}) => pumpWithApi(tester, adapter, const JobsScreen(), size: size);

/// A Text, plain or made of spans, whose text holds [part].
Finder _textWith(String part) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data ?? widget.textSpan?.toPlainText() ?? '').contains(part),
);

/// Taps a chip of the filter row. The row scrolls sideways and the labels of
/// a test are long (untranslated keys), so a chip can start off screen.
Future<void> _tapChip(WidgetTester tester, String label) async {
  final chip = find.text(label);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

/// Two jobs in two cities, one of them remote, one of them a junior's.
FakeAdapter _twoJobs() => FakeAdapter(
  (_) => jsonBody(
    _page([
      _job(
        'j1',
        'Backend Engineer',
        location: 'Ha Noi',
        level: 'Junior',
        type: 'Full-time',
      ),
      _job(
        'j2',
        'Frontend Engineer',
        company: 'Lumen Labs',
        location: 'Ho Chi Minh City',
        level: 'Mid',
        type: 'Remote',
      ),
    ]),
  ),
);

void main() {
  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
  });

  group('JobPosting', () {
    test('parses the public job, with the company from its summary', () {
      final job = JobPosting.fromJson(
        _job('j1', 'Senior Backend Engineer (Go)', company: 'Nimbus Pay'),
      );
      expect(job.id, 'j1');
      expect(job.title, 'Senior Backend Engineer (Go)');
      expect(job.companyName, 'Nimbus Pay');
      expect(job.companyId, 'e-Nimbus Pay');
      expect(job.employmentType, 'Full-time');
      expect(job.level, 'Senior');
      expect(job.openings, 2);
      expect(job.expiresAt, isNotNull);
      expect(job.createdAt, isNotNull);
    });

    test('blank text counts as missing', () {
      final job = JobPosting.fromJson(_job('j1', 'Title', location: '  '));
      expect(job.location, isNull);
    });

    test('a salary shows only with an amount and not when negotiable', () {
      expect(_posting().hasSalary, isTrue);
      expect(_posting(min: null, max: null).hasSalary, isFalse);
      expect(_posting(min: 0, max: 0).hasSalary, isFalse);
      expect(_posting(negotiable: true).hasSalary, isFalse);
    });

    test('newest first, undated last, same moment in a fixed order', () {
      final jobs = [
        JobPosting.fromJson(_job('b', 'B', createdAt: _daysAgo(2))),
        JobPosting.fromJson({..._job('z', 'Undated'), 'createdAt': null}),
        JobPosting.fromJson(_job('c', 'C', createdAt: _daysAgo(1))),
        JobPosting.fromJson(
          _job('a', 'A', createdAt: '2026-01-01T00:00:00.000Z'),
        ),
        JobPosting.fromJson(
          _job('d', 'D', createdAt: '2026-01-01T00:00:00.000Z'),
        ),
      ]..sort(JobPosting.newestFirst);
      expect(jobs.map((j) => j.id), ['c', 'b', 'a', 'd', 'z']);
    });

    test('open until the deadline; new for a few days', () {
      final now = DateTime.now();
      final open = JobPosting.fromJson(_job('j1', 'Open job'));
      final past = JobPosting.fromJson(
        _job('j2', 'Past job', expiresAt: _daysAgo(1)),
      );
      final old = JobPosting.fromJson(
        _job('j3', 'Old job', createdAt: _daysAgo(9)),
      );
      expect(open.isOpen(now), isTrue);
      expect(past.isOpen(now), isFalse);
      expect(open.isNew(now), isTrue);
      expect(old.isNew(now), isFalse);
    });
  });

  group('JobFormat', () {
    test('salary in millions of VND, trimmed', () {
      expect(JobFormat.salaryAmount(_posting()), '45–60M VND');
      expect(
        JobFormat.salaryAmount(_posting(min: 7500000, max: 10000000)),
        '7.5–10M VND',
      );
      expect(
        JobFormat.salaryAmount(_posting(min: 30000000, max: 30000000)),
        '30M VND',
      );
    });

    test('the job page splits the salary into amount and currency', () {
      final range = JobFormat.salaryParts(_posting());
      expect(range?.amount, '45–60M');
      expect(range?.unit, 'VND');
      expect(
        JobFormat.salaryParts(_posting(min: 7500000, max: 10000000))?.amount,
        '7.5–10M',
      );
      expect(
        JobFormat.salaryParts(_posting(min: 30000000, max: 30000000))?.amount,
        '30M',
      );
      expect(
        JobFormat.salaryParts(_posting(min: 1000, max: 2500, currency: 'USD'))
            ?.amount,
        '1,000–2,500',
      );
      expect(JobFormat.salaryParts(_posting(negotiable: true)), isNull);
    });

    test('open-ended and foreign salaries', () {
      expect(
        JobFormat.salaryAmount(_posting(min: 20000000, max: null)),
        'jobs.salary.from',
      );
      expect(
        JobFormat.salaryAmount(_posting(min: null, max: 30000000)),
        'jobs.salary.upTo',
      );
      expect(
        JobFormat.salaryAmount(_posting(min: 1000, max: 2500, currency: 'USD')),
        '1,000–2,500 USD',
      );
      expect(JobFormat.salaryAmount(_posting(negotiable: true)), isNull);
    });

    test('how long ago a job was posted', () {
      final now = DateTime(2026, 10, 22, 12);
      String? ago(int days) =>
          JobFormat.postedAgo(now.subtract(Duration(days: days)), now);
      expect(ago(0), 'jobs.ago.today');
      expect(ago(3), 'jobs.ago.days_other');
      expect(ago(1), 'jobs.ago.days_one');
      expect(ago(8), 'jobs.ago.weeks_one');
      expect(ago(21), 'jobs.ago.weeks_other');
      expect(ago(70), 'jobs.ago.months_other');
      expect(JobFormat.postedAgo(null, now), isNull);
    });

    test('a deadline shows its year in another year or far ahead', () {
      String date(DateTime day, DateTime now) =>
          JobFormat.shortDate(day, 'en_US', now);
      final now = DateTime(2026, 10, 23);
      expect(date(DateTime(2026, 10, 25), now), '25 Oct');
      expect(date(DateTime(2027, 1, 5), now), '5 Jan 2027');
      expect(date(DateTime(2027, 4, 11), now), '11 Apr 2027');
      expect(date(DateTime(2026, 12, 31), DateTime(2026, 3, 1)), '31 Dec 2026');
      expect(date(DateTime(2026, 6, 1), DateTime(2026, 3, 1)), '1 Jun');
    });

    test('known types and levels are translated, others shown as they are', () {
      expect(
        JobFormat.employmentLabel('Full-time'),
        'jobPostings.employmentTypes.Full-time',
      );
      expect(JobFormat.employmentLabel('Freelance'), 'Freelance');
      expect(JobFormat.levelLabel('Senior'), 'jobs.level.senior');
      expect(JobFormat.levelLabel('Principal'), 'Principal');
    });
  });

  group('publicJobsProvider', () {
    ProviderContainer containerFor(HttpClientAdapter adapter) {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [dioProvider.overrideWithValue(dio)],
      );
      addTearDown(container.dispose);
      // Keeps the auto-disposed provider alive while it loads.
      container.listen(
        publicJobsProvider,
        (previous, next) {},
        onError: (error, stackTrace) {},
      );
      return container;
    }

    test(
      'reads every page once, keeps each open job once, newest first',
      () async {
        final adapter = FakeAdapter((options) {
          final page = options.queryParameters['page'] as int;
          return jsonBody(
            page == 1
                ? _page([
                    _job('j1', 'First job', createdAt: _daysAgo(2)),
                    _job('j2', 'Closed job', expiresAt: _daysAgo(1)),
                  ], totalPages: 2)
                : _page(
                    [
                      _job('j1', 'First job', createdAt: _daysAgo(2)),
                      _job('j3', 'Third job', createdAt: _daysAgo(1)),
                    ],
                    page: 2,
                    totalPages: 2,
                  ),
          );
        });
        final container = containerFor(adapter);

        final result = await container.read(publicJobsProvider.future);

        expect(result.jobs.map((j) => j.id), ['j3', 'j1']);
        expect(adapter.requests.length, 2);
        expect(adapter.requests.first.path, '/api/v1/job-postings');
        expect(adapter.requests.first.queryParameters['limit'], 100);
      },
    );

    test('reads every page, a few at a time, however many there are', () async {
      // 25 pages: more than the old cap of 20 would have read.
      const pages = 25;
      final adapter = _CountingAdapter(
        (page) => _page(
          [_job('p$page', 'Job $page', createdAt: _daysAgo(page))],
          page: page,
          totalPages: pages,
          total: 2400,
        ),
      );
      final container = containerFor(adapter);

      final result = await container.read(publicJobsProvider.future);

      expect(adapter.pages.length, pages);
      expect(adapter.pages, containsAll([1, 20, 21, pages]));
      expect(
        adapter.mostAtOnce,
        lessThanOrEqualTo(JobConstants.fetchConcurrency),
      );
      expect(adapter.mostAtOnce, greaterThan(1));
      expect(result.jobs.first.id, 'p1');
      expect(result.jobs.length, pages);
      expect(result.total, 2400);
    });

    test('a page that fails fails the list, it is never shown short', () async {
      final adapter = FakeAdapter((options) {
        final page = options.queryParameters['page'] as int;
        if (page == 7) return jsonBody({'message': 'Boom'}, status: 500);
        return jsonBody(
          _page(
            [_job('p$page', 'Job $page', createdAt: _daysAgo(page))],
            page: page,
            totalPages: 9,
            total: 900,
          ),
        );
      });
      final container = containerFor(adapter);

      await expectLater(
        container.read(publicJobsProvider.future),
        throwsA(anything),
      );
    });

    test('fails at once, without retrying behind the scenes', () async {
      final adapter = FakeAdapter(
        (_) => jsonBody({'message': 'Boom'}, status: 500),
      );
      final container = containerFor(adapter);

      await expectLater(
        container.read(publicJobsProvider.future),
        throwsA(anything),
      );
      expect(adapter.requests.length, 1);
    });
  });

  group('JobsScreen', () {
    // Tall enough for the three cards to be built, below the search box and
    // the filter row.
    for (final size in const [Size(360, 1400), Size(390, 1400)]) {
      testWidgets('renders the list without overflow at ${size.width}px', (
        tester,
      ) async {
        final adapter = FakeAdapter(
          (_) => jsonBody(
            _page([
              _job('j1', 'Senior Backend Engineer (Go)', company: 'Nimbus Pay'),
              _job(
                'j2',
                'Principal Full-Stack TypeScript Engineer, Payments Platform',
                company: 'Lumen Labs International',
                location: 'Ho Chi Minh City',
                min: null,
                max: null,
                negotiable: true,
              ),
              _job('j3', 'Frontend Lead', createdAt: _daysAgo(30)),
            ]),
          ),
        );
        await _pump(tester, adapter, size: size);

        expect(find.text('nav.jobs'), findsOneWidget);
        expect(find.text('jobs.count_other'), findsOneWidget);
        expect(find.text('Senior Backend Engineer (Go)'), findsOneWidget);
        expect(find.text('NP'), findsNWidgets(2));
        // Only the job that says so is "Negotiable" (a job with no salary at
        // all has its own test below). Three cards stay within what the list
        // builds at once; a fourth one may not be built in a test.
        expect(find.text('jobs.salary.negotiable'), findsOneWidget);
        expect(find.textContaining('45–60M VND'), findsNWidgets(2));
        expect(find.byType(AppBadge), findsNWidgets(2));
        expect(find.text('jobs.card.new'), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('ends the list with the number of jobs seen', (tester) async {
      await _pump(
        tester,
        FakeAdapter((_) => jsonBody(_page([_job('j1', 'Only job')]))),
      );
      expect(find.text('jobs.count_one'), findsOneWidget);
      expect(find.text('jobs.end_one'), findsOneWidget);
    });

    testWidgets('ends the list with the count even past the old page cap', (
      tester,
    ) async {
      // Every page repeats one job, so the list stays short enough to show
      // its last line without scrolling.
      final adapter = FakeAdapter(
        (options) => jsonBody(
          _page(
            [_job('only', 'Only job')],
            page: options.queryParameters['page'] as int,
            totalPages: 21,
            total: 2345,
          ),
        ),
      );
      await _pump(tester, adapter);

      expect(find.text('jobs.end_one'), findsOneWidget);
    });

    testWidgets('hides the salary line for a job with no salary at all', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeAdapter(
          (_) => jsonBody(
            _page([_job('j1', 'Support Engineer', min: null, max: null)]),
          ),
        ),
      );

      expect(find.text('Support Engineer'), findsOneWidget);
      expect(find.text('jobs.salary.negotiable'), findsNothing);
      expect(find.textContaining('jobs.salary.perMonth'), findsNothing);
      expect(find.textContaining('VND'), findsNothing);
      // The rest of the card is still there.
      expect(
        find.text('jobPostings.employmentTypes.Full-time'),
        findsOneWidget,
      );
    });

    testWidgets('shows the empty state when no job is open', (tester) async {
      await _pump(tester, FakeAdapter((_) => jsonBody(_page(const []))));
      expect(find.text('jobs.empty.title'), findsOneWidget);
      expect(find.text('jobs.empty.description'), findsOneWidget);
    });

    testWidgets('pulling down on the empty state loads the jobs again', (
      tester,
    ) async {
      var open = false;
      final adapter = FakeAdapter(
        (_) => jsonBody(
          _page(
            open ? [_job('j1', 'Fresh job')] : const <Map<String, dynamic>>[],
          ),
        ),
      );
      await _pump(tester, adapter);
      expect(find.text('jobs.empty.title'), findsOneWidget);
      expect(adapter.requests.length, 1);

      open = true;
      await tester.fling(
        find.text('jobs.empty.title'),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(adapter.requests.length, 2);
      expect(find.text('jobs.empty.title'), findsNothing);
      expect(find.text('Fresh job'), findsOneWidget);
    });

    testWidgets('a quick filter narrows the list, and its chip removes it', (
      tester,
    ) async {
      await _pump(tester, _twoJobs());
      expect(find.text('Backend Engineer'), findsOneWidget);
      expect(find.text('Frontend Engineer'), findsOneWidget);

      await _tapChip(tester, 'jobs.filter.hoChiMinhCity');

      expect(find.text('Backend Engineer'), findsNothing);
      expect(find.text('Frontend Engineer'), findsOneWidget);
      expect(_textWith('jobs.count_one'), findsOneWidget);
      expect(_textWith('jobs.matchSuffix'), findsOneWidget);
      // The applied filter is the chip now; the quick ones are gone.
      expect(find.text('jobs.filter.hoChiMinhCity'), findsOneWidget);
      expect(find.text('jobs.level.senior'), findsNothing);

      await _tapChip(tester, 'jobs.filter.hoChiMinhCity');

      expect(find.text('Backend Engineer'), findsOneWidget);
      expect(find.text('Frontend Engineer'), findsOneWidget);
      expect(find.text('jobs.level.senior'), findsOneWidget);
    });

    testWidgets('no match offers to clear the filters', (tester) async {
      await _pump(tester, _twoJobs());

      await _tapChip(tester, 'jobs.level.senior');

      expect(find.text('jobs.noMatches.title'), findsOneWidget);
      expect(find.text('Backend Engineer'), findsNothing);

      await tester.tap(find.text('actions.clear'));
      await tester.pumpAndSettle();

      expect(find.text('jobs.noMatches.title'), findsNothing);
      expect(find.text('Backend Engineer'), findsOneWidget);
      expect(find.text('Frontend Engineer'), findsOneWidget);
    });

    testWidgets('searching by keyword narrows the list, its chip clears it', (
      tester,
    ) async {
      await _pump(tester, _twoJobs());

      await tester.tap(find.text('home.search.keywordPlaceholder'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'front');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('Backend Engineer'), findsNothing);
      expect(find.text('Frontend Engineer'), findsOneWidget);
      expect(find.text('jobs.filter.keyword'), findsOneWidget);

      await _tapChip(tester, 'jobs.filter.keyword');

      expect(find.text('Backend Engineer'), findsOneWidget);
      expect(find.text('Frontend Engineer'), findsOneWidget);
    });

    testWidgets('a keyword with a symbol is not searched', (tester) async {
      await _pump(tester, _twoJobs());

      await tester.tap(find.text('home.search.keywordPlaceholder'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'front<script>');
      await tester.pump();

      expect(find.text('jobs.search.invalid'), findsOneWidget);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      // Still on the search page: nothing was applied.
      expect(find.text('jobs.search.invalid'), findsOneWidget);
    });

    for (final (name, opener) in [
      ('the search page', 'home.search.keywordPlaceholder'),
      ('the filters', 'jobs.filter.title'),
    ]) {
      testWidgets('$name covers the tab bar, as a full screen', (tester) async {
        // The jobs list lives in a tab: its own navigator is under the bar.
        await pumpWithApi(
          tester,
          _twoJobs(),
          Scaffold(
            body: Navigator(
              onGenerateRoute: (_) =>
                  MaterialPageRoute(builder: (_) => const JobsScreen()),
            ),
            bottomNavigationBar: const Text('tab bar'),
          ),
        );
        expect(find.text('tab bar'), findsOneWidget);

        await tester.tap(find.text(opener));
        await tester.pumpAndSettle();

        expect(find.text('tab bar'), findsNothing);
      });
    }

    testWidgets('Filters picks a type, and shows how many jobs it matches', (
      tester,
    ) async {
      await _pump(tester, _twoJobs());

      await tester.tap(find.text('jobs.filter.title'));
      await tester.pumpAndSettle();
      expect(find.text('jobs.filter.show_other'), findsOneWidget);

      await tester.tap(find.text('jobPostings.employmentTypes.Remote'));
      await tester.pumpAndSettle();
      expect(find.text('jobs.filter.show_one'), findsOneWidget);

      await tester.tap(find.text('jobs.filter.show_one'));
      await tester.pumpAndSettle();

      expect(find.text('Backend Engineer'), findsNothing);
      expect(find.text('Frontend Engineer'), findsOneWidget);
      expect(find.text('jobs.filter.titleCount'), findsOneWidget);
    });

    testWidgets('Reset in Filters clears the choices', (tester) async {
      await _pump(tester, _twoJobs());

      await tester.tap(find.text('jobs.filter.title'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('jobPostings.employmentTypes.Remote'));
      await tester.pumpAndSettle();
      expect(find.text('jobs.filter.show_one'), findsOneWidget);

      await tester.tap(find.text('jobs.filter.reset'));
      await tester.pumpAndSettle();

      expect(find.text('jobs.filter.show_other'), findsOneWidget);
    });

    testWidgets(
      'a salary range with the minimum above the maximum is refused',
      (tester) async {
        await _pump(tester, _twoJobs());

        await tester.tap(find.text('jobs.filter.title'));
        await tester.pumpAndSettle();
        final fields = find.byType(TextField);
        await tester.ensureVisible(fields.first);
        await tester.enterText(fields.first, '50');
        await tester.enterText(fields.last, '20');
        await tester.pumpAndSettle();

        expect(find.text('jobs.filter.salaryOrder'), findsOneWidget);
        // The button that applies the filters is off while the range is empty.
        expect(
          tester.widget<AppButton>(find.byType(AppButton)).onPressed,
          isNull,
        );
      },
    );

    testWidgets('filter choices are chips side by side', (tester) async {
      // Untranslated labels are long, so the screen is wide enough for two.
      await _pump(tester, _twoJobs(), size: const Size(900, 1400));
      await tester.tap(find.text('jobs.filter.title'));
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.text('jobs.level.junior')).dy,
        tester.getTopLeft(find.text('jobs.level.intern')).dy,
      );
      // A chip is as wide as its text, not as wide as the screen.
      final chip = find.ancestor(
        of: find.text('jobs.level.junior'),
        matching: find.byType(JobChip),
      );
      expect(tester.getSize(chip).width, lessThan(400));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the sort menu orders by salary', (tester) async {
      await _pump(
        tester,
        FakeAdapter(
          (_) => jsonBody(
            _page([
              _job(
                'j1',
                'Low pay',
                min: 10000000,
                max: 12000000,
                createdAt: _daysAgo(1),
              ),
              _job(
                'j2',
                'High pay',
                min: 70000000,
                max: 90000000,
                createdAt: _daysAgo(2),
              ),
            ]),
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.text('Low pay')).dy,
        lessThan(tester.getTopLeft(find.text('High pay')).dy),
      );

      await tester.tap(find.text('jobs.sort.newest'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('jobs.sort.salaryHigh'));
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.text('High pay')).dy,
        lessThan(tester.getTopLeft(find.text('Low pay')).dy),
      );
    });

    testWidgets('shows a retryable error and never fake data', (tester) async {
      var fail = true;
      final adapter = FakeAdapter(
        (_) => fail
            ? jsonBody({'message': 'Boom'}, status: 500)
            : jsonBody(_page([_job('j1', 'Recovered job')])),
      );
      await _pump(tester, adapter);

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('jobs.loadError.title'), findsOneWidget);
      expect(find.text('jobs.loadError.description'), findsOneWidget);
      expect(find.text('Boom'), findsNothing);
      expect(adapter.requests.length, 1);

      fail = false;
      await tester.tap(find.text('errorState.retry'));
      await tester.pumpAndSettle();
      expect(find.text('Recovered job'), findsOneWidget);
    });
  });
}
