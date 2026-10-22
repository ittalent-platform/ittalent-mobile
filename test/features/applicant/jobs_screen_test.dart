import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/components/ui/app_badge.dart';
import 'package:ittalent_mobile/features/applicant/jobs/jobs_format.dart';
import 'package:ittalent_mobile/features/applicant/jobs/jobs_models.dart';
import 'package:ittalent_mobile/features/applicant/jobs/jobs_providers.dart';
import 'package:ittalent_mobile/features/applicant/jobs/jobs_screen.dart';

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
}) => {
  'items': items,
  'page': page,
  'limit': 100,
  'total': items.length,
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

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeAdapter adapter, {
  Size size = const Size(390, 844),
}) => pumpWithApi(tester, adapter, const JobsScreen(), size: size);

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
    test('reads every page once and keeps each open job once', () async {
      final adapter = FakeAdapter((options) {
        final page = options.queryParameters['page'] as int;
        return jsonBody(
          page == 1
              ? _page([
                  _job('j1', 'First job'),
                  _job('j2', 'Closed job', expiresAt: _daysAgo(1)),
                ], totalPages: 2)
              : _page(
                  [_job('j1', 'First job'), _job('j3', 'Third job')],
                  page: 2,
                  totalPages: 2,
                ),
        );
      });
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [dioProvider.overrideWithValue(dio)],
      );
      addTearDown(container.dispose);
      // Keeps the auto-disposed provider alive while it loads.
      container.listen(publicJobsProvider, (previous, next) {});

      final jobs = await container.read(publicJobsProvider.future);

      expect(jobs.map((j) => j.id), ['j1', 'j3']);
      expect(adapter.requests.length, 2);
      expect(adapter.requests.first.path, '/api/v1/job-postings');
      expect(adapter.requests.first.queryParameters['limit'], 100);
    });
  });

  group('JobsScreen', () {
    for (final size in const [Size(360, 800), Size(390, 844)]) {
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

    testWidgets('shows the empty state when no job is open', (tester) async {
      await _pump(tester, FakeAdapter((_) => jsonBody(_page(const []))));
      expect(find.text('jobs.empty.title'), findsOneWidget);
      expect(find.text('jobs.empty.description'), findsOneWidget);
    });

    testWidgets('shows a retryable error and never fake data', (tester) async {
      var fail = true;
      final adapter = FakeAdapter(
        (_) => fail
            ? jsonBody({'message': 'Boom'}, status: 500)
            : jsonBody(_page([_job('j1', 'Recovered job')])),
      );
      await _pump(tester, adapter);

      expect(find.text('jobs.loadError.title'), findsOneWidget);
      expect(find.text('Boom'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('errorState.retry'));
      await tester.pumpAndSettle();
      expect(find.text('Recovered job'), findsOneWidget);
    });
  });
}
