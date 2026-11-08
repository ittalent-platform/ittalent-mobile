import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/applicant/saved_jobs/saved_jobs_models.dart';

void main() {
  group('SavedJobsModels', () {
    test('SavedJobItem parses available item json correctly', () {
      final json = {
        'id': 'item-1',
        'jobId': 'job-1',
        'savedAt': '2026-03-01T10:00:00.000Z',
        'availability': 'available',
        'isClosingSoon': true,
        'title': 'Senior Flutter Engineer',
        'slug': 'senior-flutter-engineer',
        'enterprise': {
          'id': 'ent-1',
          'name': 'Tech Corp',
          'logoUrl': 'https://example.com/logo.png',
        },
        'location': 'Ho Chi Minh',
        'employmentType': 'full_time',
        'level': 'senior',
        'salaryMin': 30000000,
        'salaryMax': 50000000,
        'salaryNegotiable': false,
        'currency': 'VND',
        'expiresAt': '2026-04-01T00:00:00.000Z',
      };

      final item = SavedJobItem.fromJson(json);

      expect(item.id, 'item-1');
      expect(item.jobId, 'job-1');
      expect(item.isAvailable, isTrue);
      expect(item.isUnavailable, isFalse);
      expect(item.isClosingSoon, isTrue);
      expect(item.title, 'Senior Flutter Engineer');
      expect(item.enterprise?.name, 'Tech Corp');
      expect(item.hasSalary, isTrue);
    });

    test('SavedJobItem parses unavailable item json correctly', () {
      final json = {
        'id': 'item-2',
        'jobId': 'job-2',
        'savedAt': '2026-01-01T10:00:00.000Z',
        'availability': 'unavailable',
      };

      final item = SavedJobItem.fromJson(json);

      expect(item.id, 'item-2');
      expect(item.jobId, 'job-2');
      expect(item.isAvailable, isFalse);
      expect(item.isUnavailable, isTrue);
    });

    test('SavedJobsQuery formats query params correctly', () {
      const query = SavedJobsQuery(
        status: 'available',
        q: 'flutter ',
        page: 2,
        limit: 10,
      );

      final params = query.toQueryParams();
      expect(params['status'], 'available');
      expect(params['q'], 'flutter');
      expect(params['page'], 2);
      expect(params['limit'], 10);
    });

    test(
      'SavedJobsQuery copyWith clears query when passed null or clearQuery',
      () {
        const query = SavedJobsQuery(
          status: 'available',
          q: 'java',
          page: 2,
          limit: 10,
        );

        final clearedByNull = query.copyWith(q: null);
        expect(clearedByNull.q, isNull);
        expect(clearedByNull.toQueryParams()['q'], isNull);

        final clearedByFlag = query.copyWith(clearQuery: true);
        expect(clearedByFlag.q, isNull);
        expect(clearedByFlag.toQueryParams()['q'], isNull);

        final kept = query.copyWith(page: 3);
        expect(kept.q, 'java');
      },
    );

    test('SavedJobsResponse parses list of items', () {
      final json = {
        'items': [
          {
            'id': 'item-1',
            'jobId': 'job-1',
            'savedAt': '2026-03-01T10:00:00.000Z',
            'availability': 'available',
          },
        ],
        'total': 1,
        'page': 1,
        'totalPages': 1,
      };

      final response = SavedJobsResponse.fromJson(json);
      expect(response.total, 1);
      expect(response.items.length, 1);
      expect(response.items.first.id, 'item-1');
    });
  });
}
