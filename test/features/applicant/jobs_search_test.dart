import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/applicant/jobs/jobs_constants.dart';
import 'package:ittalent_mobile/features/applicant/jobs/jobs_models.dart';
import 'package:ittalent_mobile/features/applicant/jobs/jobs_providers.dart';
import 'package:ittalent_mobile/features/applicant/jobs/jobs_query.dart';
import 'package:ittalent_mobile/features/applicant/jobs/jobs_screen.dart';
import 'package:ittalent_mobile/features/applicant/jobs/widgets/job_search_field.dart';

import '../../helpers/fake_api.dart';
import '../../helpers/jobs_fixtures.dart';

const _react = 'Frontend Developer (React)';
const _senior = 'Senior Frontend Engineer';
const _go = 'Backend Engineer (Go)';

/// Newest first: Go (1 day), React (3), Senior (4). Best pay: Senior, React.
List<Map<String, dynamic>> _rows() => [
  jobJson(
    'j1',
    _react,
    company: 'Lumen Labs',
    location: 'Ho Chi Minh City',
    level: 'Mid',
    min: 25000000,
    max: 35000000,
    requirements: 'Strong GraphQL experience',
    createdAt: daysAgo(3),
  ),
  jobJson(
    'j2',
    _senior,
    company: 'Kite Health',
    min: 40000000,
    max: 55000000,
    description: 'Own the payments dashboard',
    createdAt: daysAgo(4),
  ),
  jobJson(
    'j3',
    _go,
    min: null,
    max: null,
    negotiable: true,
    createdAt: daysAgo(1),
  ),
];

List<JobPosting> _jobs() => [
  for (final row in _rows()) JobPosting.fromJson(row),
];

List<String> _ids(Iterable<JobPosting> jobs) => [for (final j in jobs) j.id];

/// Tall, so that every card is built: a list only builds the cards near the
/// screen, and test text is wide, which makes the cards tall.
Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Size size = const Size(390, 2400),
}) => pumpWithApi(
  tester,
  FakeAdapter((_) => jsonBody(jobsPage(_rows()))),
  const JobsScreen(),
  size: size,
);

Future<void> _openSearch(WidgetTester tester) async {
  await tester.tap(find.byType(JobSearchField));
  await tester.pumpAndSettle();
}

Future<void> _search(WidgetTester tester, String text) async {
  await _openSearch(tester);
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
}

/// A suggestion row: its title is rich text, with the typed part in bold.
Finder _titled(String title) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data ?? widget.textSpan?.toPlainText()) == title,
);

double _top(WidgetTester tester, String title) =>
    tester.getTopLeft(find.text(title)).dy;

void main() {
  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
  });

  group('JobsQuery', () {
    test('newest first, oldest first', () {
      expect(_ids(const JobsQuery().apply(_jobs())), ['j3', 'j1', 'j2']);
      expect(_ids(const JobsQuery(sort: JobSort.oldest).apply(_jobs())), [
        'j2',
        'j1',
        'j3',
      ]);
    });

    test('by pay, jobs without a salary last either way', () {
      expect(_ids(const JobsQuery(sort: JobSort.salaryHigh).apply(_jobs())), [
        'j2',
        'j1',
        'j3',
      ]);
      expect(_ids(const JobsQuery(sort: JobSort.salaryLow).apply(_jobs())), [
        'j1',
        'j2',
        'j3',
      ]);
    });

    test('every word must match, in any case and in any field', () {
      List<String> search(String keyword) =>
          _ids(JobsQuery(search: keyword).apply(_jobs()));
      expect(search('frontend'), ['j1', 'j2']);
      expect(search('FRONTEND react'), ['j1']);
      expect(search('kite'), ['j2']);
      expect(search('ho chi minh'), ['j1']);
      expect(search('graphql'), ['j1']); // in the requirements
      expect(search('payments dashboard'), ['j2']); // in the description
      expect(search('graphql dashboard'), isEmpty); // all words, one job
      expect(search('zzz'), isEmpty);
      expect(search('   '), ['j3', 'j1', 'j2']);
    });

    test('searching filters; sorting does not', () {
      expect(const JobsQuery(search: ' x ').isFiltered, isTrue);
      expect(const JobsQuery(search: '  ').isFiltered, isFalse);
      expect(const JobsQuery(sort: JobSort.oldest).isFiltered, isFalse);
    });

    test('a search keeps the chosen order', () {
      const query = JobsQuery(search: 'frontend', sort: JobSort.salaryHigh);
      expect(_ids(query.apply(_jobs())), ['j2', 'j1']);
    });
  });

  group('JobSearch.suggest', () {
    test('distinct titles holding the text, most common first', () {
      final jobs = [
        ..._jobs(),
        JobPosting.fromJson(jobJson('j4', _react, company: 'Nimbus Pay')),
      ];
      final suggestions = JobSearch.suggest(jobs, 'front');
      expect(suggestions.map((s) => s.title), [_react, _senior]);
      expect(suggestions.map((s) => s.count), [2, 1]);
    });

    test('nothing for blank or unknown text; capped by the limit', () {
      expect(JobSearch.suggest(_jobs(), '  '), isEmpty);
      expect(JobSearch.suggest(_jobs(), 'zzz'), isEmpty);
      expect(JobSearch.suggest(_jobs(), 'engineer', limit: 1), hasLength(1));
    });

    test('the search pattern takes names and refuses markup', () {
      for (final ok in [
        'frontend',
        'Hà Nội',
        "o'neil",
        'node.js',
        'full-stack',
      ]) {
        expect(JobConstants.searchPattern.hasMatch(ok), isTrue, reason: ok);
      }
      for (final bad in ['<script>', 'a;b', 'x%y', 'a/b', 'c++']) {
        expect(JobConstants.searchPattern.hasMatch(bad), isFalse, reason: bad);
      }
    });
  });

  group('search state', () {
    test('clearing drops the keyword and keeps the sort', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(jobsQueryProvider, (previous, next) {});
      final notifier = container.read(jobsQueryProvider.notifier);

      notifier.update(
        const JobsQuery(search: 'react', sort: JobSort.salaryHigh),
      );
      notifier.clear();

      final query = container.read(jobsQueryProvider);
      expect(query.search, isEmpty);
      expect(query.sort, JobSort.salaryHigh);
    });

    test('recent searches: newest first, no repeats, capped, removable', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(recentJobSearchesProvider.notifier);

      notifier.add('  react ');
      notifier.add('go');
      notifier.add('REACT');
      notifier.add('   ');
      expect(container.read(recentJobSearchesProvider), ['REACT', 'go']);

      for (final word in ['a', 'b', 'c', 'd', 'e']) {
        notifier.add(word);
      }
      expect(container.read(recentJobSearchesProvider), [
        'e',
        'd',
        'c',
        'b',
        'a',
      ]);

      notifier.remove('c');
      expect(container.read(recentJobSearchesProvider), ['e', 'd', 'b', 'a']);
      notifier.clear();
      expect(container.read(recentJobSearchesProvider), isEmpty);
    });
  });

  group('JobsScreen search', () {
    testWidgets('shows the search box and the sort above the list', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.byType(JobSearchField), findsOneWidget);
      expect(find.text('home.search.keywordPlaceholder'), findsOneWidget);
      expect(find.text('jobs.count_other'), findsOneWidget);
      expect(find.text('jobs.sort.newest'), findsOneWidget);
      expect(_top(tester, _go) < _top(tester, _react), isTrue);
      expect(_top(tester, _react) < _top(tester, _senior), isTrue);
    });

    testWidgets('typing offers search and job titles with their counts', (
      tester,
    ) async {
      await _pump(tester);
      await _openSearch(tester);
      await tester.enterText(find.byType(TextField), 'front');
      await tester.pump();

      expect(find.text('jobs.search.for'), findsOneWidget);
      expect(_titled(_react), findsOneWidget);
      expect(_titled(_senior), findsOneWidget);
      expect(_titled(_go), findsNothing);
      expect(find.text('jobs.count_one'), findsNWidgets(2));
      expect(find.text('5/${JobConstants.searchMaxLength}'), findsOneWidget);
    });

    testWidgets('searching from the keyboard narrows the list', (tester) async {
      await _pump(tester);
      await _search(tester, 'senior frontend');

      expect(find.byType(JobSearchField), findsOneWidget);
      expect(find.text('“senior frontend”'), findsOneWidget);
      expect(find.text('jobs.matches_one'), findsOneWidget);
      expect(find.text(_senior), findsOneWidget);
      expect(find.text(_react), findsNothing);
      expect(find.text(_go), findsNothing);
    });

    testWidgets('choosing a suggestion searches that title', (tester) async {
      await _pump(tester);
      await _openSearch(tester);
      await tester.enterText(find.byType(TextField), 'front');
      await tester.pump();
      await tester.tap(_titled(_senior));
      await tester.pumpAndSettle();

      expect(find.text('“$_senior”'), findsOneWidget);
      expect(find.text('jobs.matches_one'), findsOneWidget);
      expect(find.text(_react), findsNothing);
    });

    testWidgets('tapping the keyword removes it', (tester) async {
      await _pump(tester);
      await _search(tester, 'react');
      expect(find.text(_go), findsNothing);

      await tester.tap(find.text('“react”'));
      await tester.pumpAndSettle();

      expect(find.text('“react”'), findsNothing);
      expect(find.text('jobs.count_other'), findsOneWidget);
      expect(find.text(_go), findsOneWidget);
    });

    testWidgets('a search over a capped list says it covers only the newest', (
      tester,
    ) async {
      // The market has one page more than the app reads (every page repeats
      // the same three jobs here, so the list stays short).
      await pumpWithApi(
        tester,
        FakeAdapter(
          (options) => jsonBody(
            jobsPage(
              _rows(),
              page: options.queryParameters['page'] as int,
              totalPages: JobConstants.maxPages + 1,
              total: 2345,
            ),
          ),
        ),
        const JobsScreen(),
      );
      await _search(tester, 'kite');

      expect(find.text('jobs.matches_one'), findsOneWidget);
      expect(find.text('jobs.endPartial'), findsOneWidget);
      expect(find.text('jobs.end_one'), findsNothing);
    });

    testWidgets('cancelling leaves the list as it was', (tester) async {
      await _pump(tester);
      await _openSearch(tester);
      await tester.enterText(find.byType(TextField), 'react');
      await tester.pump();
      await tester.tap(find.text('actions.cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.text('jobs.count_other'), findsOneWidget);
      expect(find.text(_go), findsOneWidget);
    });

    testWidgets('refuses markup and long text, and searches nothing', (
      tester,
    ) async {
      await _pump(tester);
      await _openSearch(tester);

      await tester.enterText(find.byType(TextField), '<script>');
      await tester.pump();
      expect(find.text('jobs.search.invalid'), findsOneWidget);
      expect(find.text('jobs.search.for'), findsNothing);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        'a' * (JobConstants.searchMaxLength + 1),
      );
      await tester.pump();
      expect(find.text('jobs.search.tooLong'), findsOneWidget);
      expect(find.text('jobs.search.invalid'), findsNothing);
    });

    testWidgets('remembers searches, which can be reused and removed', (
      tester,
    ) async {
      await _pump(tester);
      await _search(tester, 'react');
      await tester.tap(find.text('“react”'));
      await tester.pumpAndSettle();

      await _openSearch(tester);
      expect(find.text('JOBS.SEARCH.RECENT'), findsOneWidget);
      expect(find.text('react'), findsOneWidget);

      await tester.tap(find.byTooltip('actions.close'));
      await tester.pump();
      expect(find.text('react'), findsNothing);
      expect(find.text('JOBS.SEARCH.RECENT'), findsNothing);

      await tester.tap(find.text('actions.cancel'));
      await tester.pumpAndSettle();
      await _search(tester, 'kite');
      await tester.tap(find.text('“kite”'));
      await tester.pumpAndSettle();
      await _openSearch(tester);
      await tester.tap(find.text('kite'));
      await tester.pumpAndSettle();

      expect(find.text('“kite”'), findsOneWidget);
      expect(find.text(_senior), findsOneWidget);
    });

    testWidgets('says when nothing matches, and clears the search', (
      tester,
    ) async {
      await _pump(tester);
      await _search(tester, 'zzz');

      expect(find.text('jobs.noMatch.title'), findsOneWidget);
      expect(find.text('jobs.noMatch.description'), findsOneWidget);
      expect(find.text('jobs.sort.newest'), findsNothing);

      await tester.tap(find.text('actions.clear'));
      await tester.pumpAndSettle();

      expect(find.text('jobs.noMatch.title'), findsNothing);
      expect(find.text(_go), findsOneWidget);
    });

    testWidgets('sorts by the chosen order, and keeps it when searching', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.text('jobs.sort.newest'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('jobs.sort.salaryHigh'));
      await tester.pumpAndSettle();

      expect(find.text('jobs.sort.salaryHigh'), findsOneWidget);
      expect(_top(tester, _senior) < _top(tester, _react), isTrue);
      expect(_top(tester, _react) < _top(tester, _go), isTrue);

      await _search(tester, 'frontend');
      expect(find.text('jobs.sort.salaryHigh'), findsOneWidget);
      expect(_top(tester, _senior) < _top(tester, _react), isTrue);
    });

    for (final size in const [Size(360, 800), Size(390, 844)]) {
      testWidgets('a long keyword does not overflow at ${size.width}px', (
        tester,
      ) async {
        final container = await _pump(tester, size: size);
        container
            .read(jobsQueryProvider.notifier)
            .update(JobsQuery(search: 'a' * JobConstants.searchMaxLength));
        await tester.pumpAndSettle();

        expect(find.byType(JobSearchField), findsOneWidget);
        expect(find.text('jobs.noMatch.title'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
