import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/config/routes.dart';

void main() {
  group('job routes', () {
    test('the job page and its apply page sit under /jobs', () {
      expect(AppRoutes.jobDetail('j1'), '/jobs/j1');
      expect(AppRoutes.jobApply('j1'), '/jobs/j1/apply');
    });

    test('only the apply page of a job is the apply flow', () {
      expect(AppRoutes.isJobApply(AppRoutes.jobApply('j1')), isTrue);
      expect(AppRoutes.isJobApply('/jobs/j1/apply?from=card'), isTrue);
      expect(AppRoutes.isJobApply(AppRoutes.jobDetail('j1')), isFalse);
      expect(AppRoutes.isJobApply(AppRoutes.jobs), isFalse);
      expect(AppRoutes.isJobApply('/jobs/j1/apply/extra'), isFalse);
      expect(AppRoutes.isJobApply('/companies/c1/apply'), isFalse);
      expect(AppRoutes.isJobApply('/jobs/apply'), isFalse);
    });

    group('after signing in', () {
      test('the login page carries the place to come back to', () {
        expect(AppRoutes.loginThen(null), AppRoutes.login);
        expect(
          AppRoutes.loginThen(AppRoutes.jobApply('j1')),
          '/login?from=%2Fjobs%2Fj1%2Fapply',
        );
        // A place that may not be returned to is not carried.
        expect(AppRoutes.loginThen('https://evil.example/'), AppRoutes.login);
        expect(
          Uri.parse(AppRoutes.loginThen('/jobs/j1/apply?x=a&y=b'))
              .queryParameters[AppRoutes.fromParam],
          '/jobs/j1/apply?x=a&y=b',
        );
      });

      test('only a job or a company of this app is a place to return to', () {
        expect(AppRoutes.returnTarget('/jobs/j1'), '/jobs/j1');
        expect(AppRoutes.returnTarget('/jobs/j1/apply'), '/jobs/j1/apply');
        expect(AppRoutes.returnTarget('/companies/c1'), '/companies/c1');

        for (final bad in [
          null,
          '',
          'jobs/j1',
          '/',
          '/jobs',
          '/login',
          '/login?from=/jobs/j1',
          '/my-applications/a1',
          '/profile/password',
          '//evil.example/jobs/j1',
          'https://evil.example/jobs/j1',
          'javascript:alert(1)',
          r'/\evil.example/jobs/j1',
          '/jobs//j1',
        ]) {
          expect(AppRoutes.returnTarget(bad), isNull, reason: '$bad');
        }
      });
    });
  });
}
