import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/client.dart';
import 'jobs_constants.dart';
import 'jobs_models.dart';

/// Every open public job, newest first (the order of the API is not relied
/// on). The first page says how many more there are; those are read a few at a
/// time, up to `JobConstants.maxPages`, and [PublicJobs.isPartial] tells when
/// that cap left some out. A job that moved between pages while they were read
/// is kept once.
///
/// A failure is shown at once, with a retry button: Riverpod's automatic retry
/// is off, or the skeleton would stay for a minute before the error appears.
final publicJobsProvider = FutureProvider.autoDispose<PublicJobs>(
  retry: (_, _) => null,
  (ref) async {
    final client = ref.watch(apiClientProvider);

    Future<JobsPage> fetch(int page) async {
      final response = await client.get<Map<String, dynamic>>(
        JobConstants.listPath,
        queryParameters: {'page': page, 'limit': JobConstants.fetchPageSize},
      );
      return JobsPage.fromJson(response.data ?? const {});
    }

    final first = await fetch(1);
    final lastPage = min(first.totalPages, JobConstants.maxPages);
    final pages = [first];
    for (
      var from = 2;
      from <= lastPage;
      from += JobConstants.fetchConcurrency
    ) {
      final to = min(from + JobConstants.fetchConcurrency - 1, lastPage);
      pages.addAll(
        await Future.wait([
          for (var page = from; page <= to; page++) fetch(page),
        ]),
      );
    }

    final seen = <String>{};
    final now = DateTime.now();
    final jobs = [
      for (final page in pages)
        for (final job in page.items)
          if (job.isOpen(now) && seen.add(job.id)) job,
    ]..sort(JobPosting.newestFirst);
    return PublicJobs(
      jobs: jobs,
      total: first.total,
      isPartial: first.totalPages > JobConstants.maxPages,
    );
  },
);
