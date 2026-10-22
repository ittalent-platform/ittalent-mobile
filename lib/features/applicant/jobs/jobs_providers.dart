import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/client.dart';
import 'jobs_constants.dart';
import 'jobs_models.dart';

/// Every open public job, newest first. The first page says how many more
/// there are; those are read together. A job that moved between pages while
/// they were read is kept once.
final publicJobsProvider = FutureProvider.autoDispose<List<JobPosting>>((
  ref,
) async {
  final client = ref.watch(apiClientProvider);

  Future<JobsPage> fetch(int page) async {
    final response = await client.get<Map<String, dynamic>>(
      JobConstants.listPath,
      queryParameters: {'page': page, 'limit': JobConstants.fetchPageSize},
    );
    return JobsPage.fromJson(response.data ?? const {});
  }

  final first = await fetch(1);
  final rest = await Future.wait([
    for (var page = 2; page <= first.totalPages; page++) fetch(page),
  ]);
  final seen = <String>{};
  final now = DateTime.now();
  return [
    for (final page in [first, ...rest])
      for (final job in page.items)
        if (job.isOpen(now) && seen.add(job.id)) job,
  ];
});
