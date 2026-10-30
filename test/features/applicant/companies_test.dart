import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/components/ui/app_filter_pill.dart';
import 'package:ittalent_mobile/config/routes.dart';
import 'package:ittalent_mobile/features/applicant/companies/companies_constants.dart';
import 'package:ittalent_mobile/features/applicant/companies/companies_format.dart';
import 'package:ittalent_mobile/features/applicant/companies/companies_models.dart';
import 'package:ittalent_mobile/features/applicant/companies/companies_providers.dart';
import 'package:ittalent_mobile/features/applicant/companies/companies_screen.dart';
import 'package:ittalent_mobile/features/applicant/companies/company_detail_screen.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../helpers/fake_api.dart';

typedef _Handler = ResponseBody Function(RequestOptions options);

Map<String, dynamic> _company(
  String id,
  String name, {
  String? industry = 'Fintech',
  String? size = '51-200',
  String? description = 'Payments for Southeast Asia.',
  List<String> cities = const ['Hai Phong'],
  int open = 3,
}) => {
  'id': id,
  'name': name,
  'industry': industry,
  'companySize': size,
  'shortDescription': description,
  'cities': cities,
  'openRoleCount': open,
};

Map<String, dynamic> _list(
  List<Map<String, dynamic>> items, {
  int page = 1,
  int totalPages = 1,
  int? total,
}) => {
  'items': items,
  'page': page,
  'limit': 20,
  'total': total ?? items.length,
  'totalPages': totalPages,
};

Map<String, dynamic> _detail({
  int open = 8,
  List<String> benefits = const ['Health insurance', '13th-month salary'],
}) => {
  ..._company(
    'c1',
    'NimbusPay',
    cities: const ['Ha Noi', 'Da Nang'],
    open: open,
  ),
  'description': 'We build payment rails for Southeast Asia.',
  'headquarters': {'city': 'Ha Noi', 'country': 'Vietnam'},
  'website': 'https://www.nimbuspay.example/about',
  'techStack': ['Dart', 'Go'],
  'benefits': benefits,
};

Map<String, dynamic> _job(
  String id,
  String title, {
  bool negotiable = false,
  num? min = 45000000,
  num? max = 60000000,
}) => {
  'id': id,
  'title': title,
  'location': 'Ha Noi',
  'level': 'Senior',
  'salaryMin': min,
  'salaryMax': max,
  'salaryNegotiable': negotiable,
  'currency': 'VND',
  'expiresAt': '2026-10-25T08:00:00.000Z',
};

Map<String, dynamic> _jobs(
  List<Map<String, dynamic>> items, {
  int page = 1,
  int totalPages = 1,
  int? total,
}) => {
  'items': items,
  'page': page,
  'limit': 5,
  'total': total ?? items.length,
  'totalPages': totalPages,
};

ResponseBody _oneCompany(RequestOptions options) =>
    jsonBody(_list([_company('c1', 'NimbusPay')]));

ResponseBody _twoIndustries(RequestOptions options) => jsonBody({
  'items': [
    {'industry': 'Fintech', 'count': 4},
    {'industry': 'E-commerce', 'count': 2},
  ],
});

ResponseBody _nimbusPay(RequestOptions options) => jsonBody(_detail());

ResponseBody _noJobs(RequestOptions options) => jsonBody(_jobs(const []));

/// Answers each endpoint of the feature with its handler; what a test does not
/// set answers with a plain company, two industries, a detail and no jobs.
FakeAdapter _adapter({
  _Handler? list,
  _Handler? industries,
  _Handler? detail,
  _Handler? jobs,
}) => FakeAdapter((options) {
  final path = options.path;
  if (path == CompanyConstants.listPath) {
    return (list ?? _oneCompany)(options);
  }
  if (path == CompanyConstants.industriesPath) {
    return (industries ?? _twoIndustries)(options);
  }
  if (path == CompanyConstants.jobsPath) {
    return (jobs ?? _noJobs)(options);
  }
  if (path.startsWith('/api/v1/enterprises/') && path.endsWith('/public')) {
    return (detail ?? _nimbusPay)(options);
  }
  throw StateError('Unexpected request to $path');
});

/// Any filter or keyword narrows the three companies to one.
ResponseBody _narrowing(RequestOptions options) {
  const criteria = {'keyword', 'industry', 'company_size', 'location'};
  final narrowed = options.queryParameters.keys.any(criteria.contains);
  final count = narrowed ? 1 : 3;
  return jsonBody(
    _list([
      for (var i = 0; i < count; i++) _company('c$i', 'Company $i'),
    ], total: count),
  );
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeAdapter adapter, {
  String location = AppRoutes.companies,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = adapter;
  final container = ProviderContainer(
    overrides: [dioProvider.overrideWithValue(dio)],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: AppRoutes.companies,
        builder: (context, state) => const CompaniesScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.companies}/:id',
        builder: (context, state) =>
            CompanyDetailScreen(companyId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.jobs,
        builder: (context, state) => const Scaffold(body: Text('jobs page')),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

List<RequestOptions> _listRequests(FakeAdapter adapter) => adapter.requests
    .where(
      (r) =>
          r.path == CompanyConstants.listPath &&
          r.queryParameters['limit'] == CompanyConstants.pageSize,
    )
    .toList();

void main() {
  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
  });

  group('CompaniesQuery', () {
    test('sends only the criteria that are set', () {
      expect(const CompaniesQuery().toQueryParameters(page: 1), {
        'page': 1,
        'limit': 20,
      });
      expect(
        const CompaniesQuery().toQueryParameters(page: 1, limit: 1)['limit'],
        1,
      );
    });

    test('trims the keyword and joins industries and sizes', () {
      final params = const CompaniesQuery(
        search: '  pay ',
        industries: {'Fintech', 'E-commerce'},
        sizes: {'11-50', '51-200'},
        city: 'Ha Noi',
      ).toQueryParameters(page: 2);
      expect(params, {
        'page': 2,
        'limit': 20,
        'keyword': 'pay',
        'industry': 'Fintech,E-commerce',
        'company_size': '11-50,51-200',
        'location': 'Ha Noi',
      });
    });

    test('queries are equal when their choices are, in any order', () {
      expect(
        const CompaniesQuery(industries: {'a', 'b'}, sizes: {'1-10'}),
        const CompaniesQuery(industries: {'b', 'a'}, sizes: {'1-10'}),
      );
      expect(
        const CompaniesQuery(industries: {'a', 'b'}).hashCode,
        const CompaniesQuery(industries: {'b', 'a'}).hashCode,
      );
      expect(
        const CompaniesQuery(industries: {'a'}),
        isNot(const CompaniesQuery(industries: {'b'})),
      );
      expect(
        const CompaniesQuery(city: 'Ha Noi'),
        isNot(const CompaniesQuery()),
      );
    });

    test('the search is not a filter, but it does narrow the list', () {
      const searched = CompaniesQuery(search: 'x');
      expect(searched.filterCount, 0);
      expect(searched.isFiltered, isTrue);
      const filtered = CompaniesQuery(industries: {'a'}, city: 'Ha Noi');
      expect(filtered.filterCount, 2);
      expect(const CompaniesQuery().isFiltered, isFalse);
    });

    test('clearCity drops the city only', () {
      final query = const CompaniesQuery(
        search: 'x',
        sizes: {'1-10'},
        city: 'Ha Noi',
      ).copyWith(clearCity: true);
      expect(query.city, isNull);
      expect(query.search, 'x');
      expect(query.sizes, {'1-10'});
    });
  });

  group('models', () {
    test('a company summary treats blank strings as missing', () {
      final company = CompanySummary.fromJson({
        'id': 'c1',
        'name': 'NimbusPay',
        'industry': '  ',
        'companySize': '51-200',
        'shortDescription': '',
        'cities': ['Ha Noi', ' ', 7],
        'openRoleCount': 8,
      });
      expect(company.industry, isNull);
      expect(company.shortDescription, isNull);
      expect(company.companySize, '51-200');
      expect(company.cities, ['Ha Noi']);
      expect(company.openRoleCount, 8);
    });

    test('a page without fields is an empty first page', () {
      final page = CompaniesPage.fromJson(const {});
      expect(page.items, isEmpty);
      expect(page.page, 1);
      expect(page.totalPages, 0);
      expect(page.total, 0);
    });

    test('a company detail keeps what the page shows', () {
      final company = CompanyDetail.fromJson({
        ..._detail(),
        'website': '  ',
        'techStack': ['Dart', ' ', 42],
        'headquarters': {'city': ' Ha Noi '},
      });
      expect(company.id, 'c1');
      expect(company.name, 'NimbusPay');
      expect(company.headquarters, 'Ha Noi');
      expect(company.website, isNull);
      expect(company.techStack, ['Dart']);
      expect(company.benefits, ['Health insurance', '13th-month salary']);
      expect(CompanyDetail.fromJson(const {}).headquarters, isNull);
    });

    test('a negotiable job shows no amount', () {
      final job = CompanyJob.fromJson(_job('j1', 'Dev', negotiable: true));
      expect(job.hasSalary, isFalse);
      expect(CompanyJob.fromJson(_job('j2', 'Dev')).hasSalary, isTrue);
      expect(
        CompanyJob.fromJson(_job('j3', 'Dev', min: null, max: null)).hasSalary,
        isFalse,
      );
      expect(CompanyJob.fromJson(_job('j4', 'Dev')).expiresAt, isNotNull);
    });
  });

  group('CompanyFormat', () {
    test('sizes use an en dash and subtitles skip what is missing', () {
      expect(CompanyFormat.sizeRange('51-200'), '51–200');
      expect(CompanyFormat.sizeRange('1000+'), '1000+');
      expect(
        CompanyFormat.subtitle(
          CompanySummary.fromJson(_company('c1', 'A', size: null)),
        ),
        'Fintech',
      );
      expect(
        CompanyFormat.subtitle(CompanySummary.fromJson(_company('c1', 'A'))),
        'Fintech · home.companies.size',
      );
      expect(
        CompanyFormat.pageSubtitle(CompanyDetail.fromJson(_detail())),
        'Fintech · home.companies.size · Ha Noi',
      );
    });

    test('counts pick the singular or the plural key', () {
      expect(
        CompanyFormat.countText('companies.count', 1),
        'companies.count_one',
      );
      expect(
        CompanyFormat.countText('companies.count', 0),
        'companies.count_other',
      );
      expect(CompanyFormat.openJobs(0), 'companies.card.noOpenJobs');
      expect(CompanyFormat.openJobs(1), 'companies.card.openJobs_one');
      expect(CompanyFormat.openJobs(8), 'companies.card.openJobs_other');
    });

    test('salaries are in millions for VND and grouped for other money', () {
      String? amount(num? min, num? max, {String currency = 'VND'}) =>
          CompanyFormat.salaryAmount(
            CompanyJob(
              id: 'j',
              title: 'Dev',
              salaryMin: min,
              salaryMax: max,
              currency: currency,
            ),
          );
      expect(amount(45000000, 60000000), '45–60M VND');
      expect(amount(25000000, 25000000), '25M VND');
      expect(amount(7500000, 12000000), '7.5–12M VND');
      expect(amount(1500, 2500, currency: 'USD'), '1,500–2,500 USD');
      expect(amount(20000000, null), 'companies.jobs.salaryFrom');
      expect(amount(null, 30000000), 'companies.jobs.salaryUpTo');
      expect(amount(null, null), isNull);
      expect(amount(0, 0), isNull);
    });

    test('negotiable is said only for jobs that are', () {
      expect(
        CompanyFormat.salaryText(
          CompanyJob.fromJson(_job('j', 'D', negotiable: true)),
        ),
        'companies.jobs.negotiable',
      );
      expect(
        CompanyFormat.salaryText(
          CompanyJob.fromJson(_job('j', 'D', min: null, max: null)),
        ),
        isNull,
      );
    });

    test('a job place joins the location and the level', () {
      expect(
        CompanyFormat.jobPlace(CompanyJob.fromJson(_job('j', 'D'))),
        'Ha Noi · Senior',
      );
      expect(
        CompanyFormat.jobPlace(const CompanyJob(id: 'j', title: 'D')),
        isNull,
      );
    });

    test('a deadline shows its year when it is far away', () {
      final now = DateTime(2026, 10, 21);
      expect(
        CompanyFormat.shortDate(DateTime(2026, 10, 25), 'en_US', now),
        '25 Oct',
      );
      expect(
        CompanyFormat.shortDate(DateTime(2027, 4, 11), 'en_US', now),
        '11 Apr 2027',
      );
      expect(
        CompanyFormat.shortDate(
          DateTime(2026, 12, 30),
          'en_US',
          DateTime(2026, 1, 1),
        ),
        '30 Dec 2026',
      );
      expect(CompanyFormat.applyBy(null, 'en_US', now), isNull);
    });

    test('only plain web addresses open', () {
      expect(
        CompanyFormat.websiteUri('nimbuspay.example'),
        Uri.parse('https://nimbuspay.example'),
      );
      expect(CompanyFormat.websiteUri(' http://a.example/x ')?.scheme, 'http');
      expect(CompanyFormat.websiteUri('javascript:alert(1)'), isNull);
      expect(CompanyFormat.websiteUri('ftp://files.example'), isNull);
      expect(CompanyFormat.websiteUri('https://user:pw@a.example'), isNull);
      expect(CompanyFormat.websiteUri('mailto:me@a.example'), isNull);
      expect(CompanyFormat.websiteUri('  '), isNull);
      expect(CompanyFormat.websiteUri(null), isNull);
      expect(
        CompanyFormat.websiteLabel(
          Uri.parse('https://www.nimbuspay.example/about'),
        ),
        'nimbuspay.example',
      );
    });
  });

  group('CompaniesScreen', () {
    for (final size in const [Size(360, 800), Size(390, 844)]) {
      testWidgets('lists companies without overflow at ${size.width}px', (
        tester,
      ) async {
        final adapter = _adapter(
          list: (_) => jsonBody(
            _list([
              _company(
                'c1',
                'NimbusPay',
                cities: const ['Ha Noi', 'Ho Chi Minh City'],
                open: 8,
              ),
              _company(
                'c2',
                'Pixel Labs',
                industry: null,
                size: null,
                description: null,
                cities: const [],
                open: 0,
              ),
              _company(
                'c3',
                'A company with a very long name that has to be cut short',
                industry: 'E-commerce',
                open: 1,
              ),
            ]),
          ),
        );
        await _pump(tester, adapter, size: size);

        expect(find.text('NimbusPay'), findsOneWidget);
        expect(find.text('Payments for Southeast Asia.'), findsNWidgets(2));
        expect(find.text('Fintech · home.companies.size'), findsOneWidget);
        expect(find.text('Ha Noi, Ho Chi Minh City'), findsOneWidget);
        expect(find.text('companies.card.openJobs_other'), findsOneWidget);
        expect(find.text('companies.card.openJobs_one'), findsOneWidget);
        expect(find.text('companies.card.noOpenJobs'), findsOneWidget);
        expect(find.textContaining('companies.count_other'), findsOneWidget);
        expect(adapter.requests.first.path, CompanyConstants.listPath);
        expect(adapter.requests.first.queryParameters, {
          'page': 1,
          'limit': 20,
        });
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('says there are no companies when there are none', (
      tester,
    ) async {
      await _pump(
        tester,
        _adapter(list: (_) => jsonBody(_list(const []))),
        size: const Size(900, 800),
      );
      expect(find.text('companies.empty.title'), findsOneWidget);
      expect(find.text('companies.noMatches.title'), findsNothing);
    });

    testWidgets('the Jobs title goes to the job list', (tester) async {
      await _pump(tester, _adapter());
      await tester.tap(find.text('nav.jobs'));
      await tester.pumpAndSettle();
      expect(find.text('jobs page'), findsOneWidget);
    });

    testWidgets('searches on the server after the debounce, trimmed', (
      tester,
    ) async {
      final adapter = _adapter(list: _narrowing);
      await _pump(tester, adapter);
      expect(find.text('Company 2'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '  pay ');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(_listRequests(adapter).last.queryParameters['keyword'], 'pay');
      expect(find.text('Company 2'), findsNothing);
      expect(find.text('Company 0'), findsOneWidget);
    });

    testWidgets('spaces alone are no keyword', (tester) async {
      final adapter = _adapter(list: _narrowing);
      await _pump(tester, adapter);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(
        _listRequests(adapter).last.queryParameters.containsKey('keyword'),
        isFalse,
      );
      expect(find.text('Company 2'), findsOneWidget);
    });

    testWidgets('a keyword over 100 characters is not sent', (tester) async {
      final adapter = _adapter(list: _narrowing);
      await _pump(tester, adapter);
      final before = adapter.requests.length;

      await tester.enterText(find.byType(TextField), 'a' * 101);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('companies.errors.keywordTooLong'), findsOneWidget);
      expect(adapter.requests.length, before);
    });

    testWidgets('no match offers to clear the search', (tester) async {
      final adapter = _adapter(
        list: (options) => options.queryParameters.containsKey('keyword')
            ? jsonBody(_list(const []))
            : jsonBody(_list([_company('c1', 'NimbusPay')])),
      );
      // Untranslated keys are long, so give the action button room.
      final container = await _pump(
        tester,
        adapter,
        size: const Size(900, 800),
      );

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('companies.noMatches.title'), findsOneWidget);

      await tester.tap(find.text('companies.noMatches.clear'));
      await tester.pumpAndSettle();
      expect(find.text('NimbusPay'), findsOneWidget);
      expect(find.text('zzz'), findsNothing);
      expect(container.read(companiesQueryProvider), const CompaniesQuery());
    });

    testWidgets('the Industry pill picks industries, with a live count', (
      tester,
    ) async {
      final adapter = _adapter(list: _narrowing);
      await _pump(tester, adapter, size: const Size(900, 1200));

      await tester.tap(find.text('companies.filter.industry'));
      await tester.pumpAndSettle();
      expect(find.text('Fintech'), findsOneWidget);
      expect(find.text('E-commerce'), findsOneWidget);
      // Nothing chosen yet: all three companies match.
      expect(find.text('companies.filter.show_other'), findsOneWidget);

      await tester.tap(find.text('Fintech'));
      await tester.pumpAndSettle();
      expect(find.text('companies.filter.show_one'), findsOneWidget);
      // The list behind the sheet has not changed until it is applied.
      expect(_listRequests(adapter), hasLength(1));

      await tester.tap(find.text('companies.filter.show_one'));
      await tester.pumpAndSettle();

      expect(
        _listRequests(adapter).last.queryParameters['industry'],
        'Fintech',
      );
      expect(find.widgetWithText(AppFilterPill, 'Fintech'), findsOneWidget);
      expect(find.text('Company 1'), findsNothing);
    });

    testWidgets('Filters opens every group; size and city apply together', (
      tester,
    ) async {
      final adapter = _adapter(list: _narrowing);
      final container = await _pump(
        tester,
        adapter,
        size: const Size(900, 1400),
      );

      await tester.tap(find.text('companies.filter.title'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('51–200'));
      await tester.tap(find.text('Can Tho'));
      await tester.pumpAndSettle();
      // A city is a single choice: the second one replaces the first.
      await tester.tap(find.text('Da Nang'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('companies.filter.show_one'));
      await tester.pumpAndSettle();

      final params = _listRequests(adapter).last.queryParameters;
      expect(params['company_size'], '51-200');
      expect(params['location'], 'Da Nang');
      expect(
        container.read(companiesQueryProvider),
        const CompaniesQuery(sizes: {'51-200'}, city: 'Da Nang'),
      );
      expect(find.widgetWithText(AppFilterPill, '51–200'), findsOneWidget);
      expect(find.widgetWithText(AppFilterPill, 'Da Nang'), findsOneWidget);
    });

    testWidgets('Reset in the sheet clears the choices', (tester) async {
      final adapter = _adapter(list: _narrowing);
      final container = await _pump(
        tester,
        adapter,
        size: const Size(900, 1400),
      );
      container
          .read(companiesQueryProvider.notifier)
          .update(const CompaniesQuery(sizes: {'51-200'}, city: 'Ha Noi'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('companies.filter.title'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('companies.filter.reset'));
      await tester.pumpAndSettle();
      expect(find.text('companies.filter.reset'), findsNothing);
      await tester.tap(find.text('companies.filter.show_other'));
      await tester.pumpAndSettle();

      expect(container.read(companiesQueryProvider).isFiltered, isFalse);
    });

    testWidgets('shows a retryable error and never fake data', (tester) async {
      var fail = true;
      final adapter = _adapter(
        list: (_) => fail
            ? jsonBody({'message': 'Boom'}, status: 500)
            : jsonBody(_list([_company('c1', 'Recovered company')])),
      );
      await _pump(tester, adapter);

      expect(find.text('companies.loadError.title'), findsOneWidget);
      expect(find.text('Recovered company'), findsNothing);

      fail = false;
      await tester.tap(find.text('errorState.retry'));
      await tester.pumpAndSettle();
      expect(find.text('Recovered company'), findsOneWidget);
    });

    testWidgets('loads the next page when scrolled to the end', (tester) async {
      final adapter = _adapter(
        list: (options) => jsonBody(
          options.queryParameters['page'] == 1
              ? _list(
                  [
                    for (var i = 0; i < 8; i++)
                      _company('p1-$i', 'First page $i'),
                  ],
                  totalPages: 2,
                  total: 9,
                )
              : _list(
                  [_company('p2-0', 'Second page company')],
                  page: 2,
                  totalPages: 2,
                  total: 9,
                ),
        ),
      );
      await _pump(tester, adapter);

      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      expect(_listRequests(adapter).last.queryParameters['page'], 2);
      expect(find.text('Second page company'), findsOneWidget);
    });

    testWidgets('a failed next page keeps the list and retries on tap only', (
      tester,
    ) async {
      var fail = true;
      final adapter = _adapter(
        list: (options) {
          if (options.queryParameters['page'] == 1) {
            return jsonBody(
              _list(
                [
                  for (var i = 0; i < 8; i++)
                    _company('p1-$i', 'First page $i'),
                ],
                totalPages: 2,
                total: 9,
              ),
            );
          }
          return fail
              ? jsonBody({'message': 'Boom'}, status: 500)
              : jsonBody(
                  _list(
                    [_company('p2-0', 'Second page company')],
                    page: 2,
                    totalPages: 2,
                    total: 9,
                  ),
                );
        },
      );
      await _pump(tester, adapter);

      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.text('companies.loadMoreFailed'), findsOneWidget);
      // The list is scrolled to its end: the last card of page 1 is on show.
      expect(find.text('First page 7'), findsOneWidget);

      // Scrolling again does not ask again.
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      final secondPageRequests = _listRequests(adapter)
          .where((r) => r.queryParameters['page'] == 2);
      expect(secondPageRequests, hasLength(1));

      fail = false;
      await tester.ensureVisible(find.text('errorState.retry'));
      await tester.tap(find.text('errorState.retry'));
      await tester.pumpAndSettle();
      expect(find.text('Second page company'), findsOneWidget);
      expect(find.text('companies.loadMoreFailed'), findsNothing);
    });

    testWidgets('a card opens the company page and back returns', (
      tester,
    ) async {
      await _pump(tester, _adapter());

      await tester.tap(find.text('NimbusPay'));
      await tester.pumpAndSettle();
      expect(find.byType(CompanyDetailScreen), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.chevronLeft));
      await tester.pumpAndSettle();
      expect(find.byType(CompaniesScreen), findsOneWidget);
      expect(find.byType(CompanyDetailScreen), findsNothing);
    });
  });

  group('CompanyDetailScreen', () {
    const detailLocation = '/companies/c1';

    testWidgets('About shows the story, the stack and the facts', (
      tester,
    ) async {
      final adapter = _adapter();
      await _pump(tester, adapter, location: detailLocation);

      expect(adapter.requests.first.path, '/api/v1/enterprises/c1/public');
      expect(find.text('NimbusPay'), findsOneWidget);
      expect(
        find.text('Fintech · home.companies.size · Ha Noi'),
        findsOneWidget,
      );
      expect(
        find.text('We build payment rails for Southeast Asia.'),
        findsOneWidget,
      );
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('Go'), findsOneWidget);
      // Facts: industry, headquarters, offices (two cities) and website.
      expect(find.text('Fintech'), findsOneWidget);
      expect(find.text('Ha Noi'), findsOneWidget);
      expect(find.text('Ha Noi, Da Nang'), findsOneWidget);
      expect(find.text('nimbuspay.example'), findsOneWidget);
      expect(find.text('companies.page.seeJobs_other'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits a 360px screen', (tester) async {
      await _pump(
        tester,
        _adapter(),
        location: detailLocation,
        size: const Size(360, 800),
      );
      expect(find.text('NimbusPay'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('See open jobs opens the Jobs tab with the open jobs', (
      tester,
    ) async {
      final adapter = _adapter(
        jobs: (_) => jsonBody(
          _jobs([
            _job('j1', 'Senior Flutter Developer'),
            _job('j2', 'QA Engineer', negotiable: true),
          ], total: 2),
        ),
      );
      await _pump(tester, adapter, location: detailLocation);

      await tester.tap(find.text('companies.page.seeJobs_other'));
      await tester.pumpAndSettle();

      final request = adapter.requests.last;
      expect(request.path, CompanyConstants.jobsPath);
      expect(request.queryParameters, {
        'enterprise_id': 'c1',
        'page': 1,
        'limit': 5,
      });
      expect(find.text('Senior Flutter Developer'), findsOneWidget);
      expect(find.text('Ha Noi · Senior'), findsNWidgets(2));
      expect(find.textContaining('45–60M VND'), findsOneWidget);
      expect(find.textContaining('companies.jobs.negotiable'), findsOneWidget);
      // The bar belongs to the other tabs.
      expect(find.text('companies.page.seeJobs_other'), findsNothing);
      expect(find.text('nimbuspay.example'), findsNothing);
    });

    testWidgets('the Jobs tab loads five more with Load more', (tester) async {
      final adapter = _adapter(
        jobs: (options) => jsonBody(
          options.queryParameters['page'] == 1
              ? _jobs(
                  [for (var i = 0; i < 5; i++) _job('a$i', 'First job $i')],
                  totalPages: 2,
                  total: 6,
                )
              : _jobs(
                  [_job('b0', 'Sixth job')],
                  page: 2,
                  totalPages: 2,
                  total: 6,
                ),
        ),
      );
      await _pump(
        tester,
        adapter,
        location: detailLocation,
        // Untranslated tab names are long, so give the tabs room to be tapped.
        size: const Size(900, 1400),
      );

      await tester.tap(find.text('companies.tabs.jobs'));
      await tester.pumpAndSettle();
      expect(find.text('First job 4'), findsOneWidget);
      expect(find.text('Sixth job'), findsNothing);
      expect(find.textContaining('companies.jobs.showing'), findsOneWidget);

      await tester.tap(find.text('companies.jobs.loadMore'));
      await tester.pumpAndSettle();

      expect(adapter.requests.last.queryParameters['page'], 2);
      expect(find.text('Sixth job'), findsOneWidget);
      expect(find.text('First job 0'), findsOneWidget);
      expect(find.text('companies.jobs.loadMore'), findsNothing);
    });

    testWidgets('a company without open jobs says so and goes back', (
      tester,
    ) async {
      final adapter = _adapter(detail: (_) => jsonBody(_detail(open: 0)));
      await _pump(
        tester,
        adapter,
        location: detailLocation,
        size: const Size(900, 1000),
      );
      expect(find.text('companies.page.seeJobs_other'), findsNothing);
      expect(find.text('companies.page.browse'), findsOneWidget);

      await tester.tap(find.text('companies.tabs.jobs'));
      await tester.pumpAndSettle();
      expect(find.text('companies.jobs.empty.title'), findsOneWidget);

      // The page was opened by a link, so there is no list behind it.
      await tester.tap(find.text('companies.jobs.empty.browse'));
      await tester.pumpAndSettle();
      expect(find.byType(CompaniesScreen), findsOneWidget);
    });

    testWidgets('the Jobs tab shows a retryable error', (tester) async {
      var fail = true;
      final adapter = _adapter(
        jobs: (_) => fail
            ? jsonBody({'message': 'Boom'}, status: 500)
            : jsonBody(_jobs([_job('j1', 'Recovered job')])),
      );
      await _pump(
        tester,
        adapter,
        location: detailLocation,
        size: const Size(900, 1000),
      );

      await tester.tap(find.text('companies.tabs.jobs'));
      await tester.pumpAndSettle();
      expect(find.text('companies.jobs.loadError.title'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('errorState.retry'));
      await tester.pumpAndSettle();
      expect(find.text('Recovered job'), findsOneWidget);
    });

    testWidgets('Benefits lists what the company offers', (tester) async {
      await _pump(
        tester,
        _adapter(),
        location: detailLocation,
        size: const Size(900, 1000),
      );
      await tester.tap(find.text('companies.tabs.benefits'));
      await tester.pumpAndSettle();
      expect(find.text('Health insurance'), findsOneWidget);
      expect(find.text('13th-month salary'), findsOneWidget);
    });

    testWidgets('Benefits says so when there are none', (tester) async {
      await _pump(
        tester,
        _adapter(detail: (_) => jsonBody(_detail(benefits: const []))),
        location: detailLocation,
        size: const Size(900, 1000),
      );
      await tester.tap(find.text('companies.tabs.benefits'));
      await tester.pumpAndSettle();
      expect(find.text('companies.benefits.empty.title'), findsOneWidget);
    });

    for (final status in const [404, 400]) {
      testWidgets('a company that is not available ($status) says so', (
        tester,
      ) async {
        final adapter = _adapter(
          detail: (_) => jsonBody({'message': 'Not found'}, status: status),
        );
        await _pump(
          tester,
          adapter,
          location: detailLocation,
          size: const Size(900, 1000),
        );

        expect(find.text('companies.notAvailable.title'), findsOneWidget);
        expect(find.text('companies.page.loadError.title'), findsNothing);

        await tester.tap(find.text('companies.notAvailable.back'));
        await tester.pumpAndSettle();
        expect(find.byType(CompaniesScreen), findsOneWidget);
      });
    }

    testWidgets('a server error offers to retry', (tester) async {
      var fail = true;
      final adapter = _adapter(
        detail: (_) => fail
            ? jsonBody({'message': 'Boom'}, status: 500)
            : jsonBody(_detail()),
      );
      await _pump(tester, adapter, location: detailLocation);
      expect(find.text('companies.page.loadError.title'), findsOneWidget);
      expect(find.text('companies.notAvailable.title'), findsNothing);

      fail = false;
      await tester.tap(find.text('errorState.retry'));
      await tester.pumpAndSettle();
      expect(find.text('NimbusPay'), findsOneWidget);
    });
  });
}
