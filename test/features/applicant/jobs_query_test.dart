import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/applicant/jobs/jobs_models.dart';
import 'package:ittalent_mobile/features/applicant/jobs/jobs_query.dart';

JobPosting _job(
  String id, {
  String title = 'Title',
  String company = 'Acme',
  String? location,
  String? type,
  String? level,
  num? min,
  num? max,
  bool negotiable = false,
  String currency = 'VND',
  String? requirements,
  String? description,
  DateTime? createdAt,
}) => JobPosting(
  id: id,
  title: title,
  companyId: 'c-$company',
  companyName: company,
  location: location,
  employmentType: type,
  level: level,
  salaryMin: min,
  salaryMax: max,
  salaryNegotiable: negotiable,
  currency: currency,
  requirements: requirements,
  description: description,
  createdAt: createdAt,
);

/// Five jobs, newest first: 3, 2, 1, 4, 5.
final List<JobPosting> _jobs = [
  _job(
    '1',
    title: 'Frontend Developer (React)',
    company: 'Lumen Labs',
    location: 'Ho Chi Minh City',
    type: 'Full-time',
    level: 'Mid',
    min: 25000000,
    max: 35000000,
    requirements: 'React TypeScript',
    createdAt: DateTime(2026, 10, 1),
  ),
  _job(
    '2',
    title: 'Senior Frontend Engineer',
    company: 'Kite Health',
    location: 'Ho Chi Minh City',
    type: 'Full-time',
    level: 'Senior',
    min: 40000000,
    max: 55000000,
    requirements: 'Vue',
    createdAt: DateTime(2026, 10, 2),
  ),
  _job(
    '3',
    title: 'Backend (Go)',
    company: 'Nimbus Pay',
    location: 'Hà Nội',
    type: 'Remote',
    level: 'senior',
    negotiable: true,
    createdAt: DateTime(2026, 10, 3),
  ),
  _job(
    '4',
    title: 'QA',
    company: 'Orbit',
    location: 'Da Nang',
    type: 'Internship',
    level: 'Intern',
    min: 5000000,
    max: 8000000,
    createdAt: DateTime(2026, 9, 1),
  ),
  _job(
    '5',
    title: 'Data',
    company: 'X',
    location: 'HN',
    type: 'Contract',
    level: 'Lead',
    min: 1000,
    max: 2000,
    currency: 'USD',
    createdAt: DateTime(2026, 8, 1),
  ),
];

List<String> _ids(JobsQuery query) => [
  for (final job in query.apply(_jobs)) job.id,
];

void main() {
  group('JobSearch', () {
    test('folds case and Vietnamese accents, keeping the length', () {
      expect(JobSearch.fold('Hà Nội ĐÀ NẴNG'), 'ha noi da nang');
      expect(JobSearch.fold('Đặng Thị').length, 'Đặng Thị'.length);
    });

    test('suggests titles that contain the text, most common first', () {
      final suggestions = JobSearch.suggest(_jobs, 'front');
      expect(
        [for (final s in suggestions) '${s.title}:${s.count}'],
        ['Frontend Developer (React):1', 'Senior Frontend Engineer:1'],
      );
      expect(JobSearch.suggest(_jobs, '  '), isEmpty);
    });
  });

  group('JobsQuery', () {
    test('lists newest first, or oldest first', () {
      expect(_ids(const JobsQuery()), ['3', '2', '1', '4', '5']);
      expect(_ids(const JobsQuery(sort: JobSort.oldest)), [
        '5',
        '4',
        '1',
        '2',
        '3',
      ]);
    });

    test('a keyword matches every word in the text, ignoring accents', () {
      expect(_ids(const JobsQuery(search: 'react')), ['1']);
      expect(_ids(const JobsQuery(search: 'ha noi')), ['3']);
      expect(_ids(const JobsQuery(search: 'frontend kite')), ['2']);
      expect(_ids(const JobsQuery(search: 'nothing like this')), isEmpty);
    });

    test('filters by type, level and city', () {
      expect(_ids(const JobsQuery(types: {'Remote'})), ['3']);
      expect(_ids(const JobsQuery(levels: {'senior'})), ['3', '2']);
      expect(_ids(const JobsQuery(cities: {'Ho Chi Minh'})), ['2', '1']);
    });

    test('a salary range keeps jobs whose own range overlaps it', () {
      expect(_ids(const JobsQuery(salaryMin: 20)), ['3', '2', '1', '5']);
      expect(
        _ids(
          const JobsQuery(
            salaryMin: 30,
            salaryMax: 40,
            includeNegotiable: false,
          ),
        ),
        ['2', '1'],
      );
      expect(_ids(const JobsQuery(salaryMax: 10, includeNegotiable: false)), [
        '4',
      ]);
    });

    test('jobs without a VND amount follow "include negotiable"', () {
      expect(_ids(const JobsQuery(salaryMin: 20, includeNegotiable: false)), [
        '2',
        '1',
      ]);
    });

    test('sorts by salary, jobs without one last', () {
      expect(_ids(const JobsQuery(sort: JobSort.salaryHigh)), [
        '2',
        '1',
        '4',
        '3',
        '5',
      ]);
      expect(_ids(const JobsQuery(sort: JobSort.salaryLow)), [
        '4',
        '1',
        '2',
        '3',
        '5',
      ]);
    });

    test('counts what narrows the list, and not the sort order', () {
      expect(
        const JobsQuery(
          search: 'a',
          types: {'x', 'y'},
          levels: {'z'},
          salaryMin: 3,
        ).filterCount,
        5,
      );
      expect(const JobsQuery(search: '   ').isFiltered, isFalse);
      expect(const JobsQuery(sort: JobSort.oldest).isFiltered, isFalse);
    });

    test('a range is valid unless its minimum is above its maximum', () {
      expect(
        const JobsQuery(salaryMin: 30, salaryMax: 20).hasValidSalaryRange,
        isFalse,
      );
      expect(
        const JobsQuery(salaryMin: 20, salaryMax: 20).hasValidSalaryRange,
        isTrue,
      );
      expect(const JobsQuery(salaryMin: 20).hasValidSalaryRange, isTrue);
    });

    test('clearing drops the filters and keeps the sort order', () {
      final cleared = const JobsQuery(
        search: 'a',
        types: {'Remote'},
        salaryMin: 3,
        sort: JobSort.oldest,
      ).cleared();
      expect(cleared.isFiltered, isFalse);
      expect(cleared.search, '');
      expect(cleared.sort, JobSort.oldest);
    });

    test('copyWith can drop the salary range', () {
      final query = const JobsQuery(
        salaryMin: 3,
        salaryMax: 4,
      ).copyWith(clearSalary: true);
      expect(query.hasSalaryRange, isFalse);
    });
  });
}
