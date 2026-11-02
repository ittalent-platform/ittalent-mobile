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
  });
}
