import 'jobs_constants.dart';
import 'jobs_models.dart';

enum JobSort { newest, oldest, salaryHigh, salaryLow }

/// What the job list is narrowed and ordered by. The API cannot filter by
/// these, so they are applied to the jobs already read (see
/// `publicJobsProvider`), which also gives live counts without a request.
class JobsQuery {
  const JobsQuery({this.search = '', this.sort = JobSort.newest});

  final String search;
  final JobSort sort;

  /// Sorting does not narrow the list, so it is not a filter.
  bool get isFiltered => search.trim().isNotEmpty;

  JobsQuery copyWith({String? search, JobSort? sort}) =>
      JobsQuery(search: search ?? this.search, sort: sort ?? this.sort);

  /// The matching jobs in the chosen order.
  List<JobPosting> apply(List<JobPosting> jobs) {
    final keyword = search.trim();
    final matching = [
      for (final job in jobs)
        if (keyword.isEmpty || JobSearch.matches(job, keyword)) job,
    ];
    matching.sort(_compare);
    return matching;
  }

  /// The best salary of a job, 0 when it has none.
  static num _top(JobPosting job) => !job.hasSalary
      ? 0
      : (job.salaryMax ?? 0) > (job.salaryMin ?? 0)
      ? job.salaryMax!
      : job.salaryMin!;

  /// Ascending salary rank: jobs without a salary go last.
  static num _lowRank(JobPosting job) {
    final top = _top(job);
    return top == 0 ? double.infinity : top;
  }

  int _compare(JobPosting a, JobPosting b) {
    final newest = JobPosting.newestFirst(a, b);
    int byPay(num x, num y) {
      final result = x.compareTo(y);
      return result != 0 ? result : newest;
    }

    return switch (sort) {
      JobSort.newest => newest,
      JobSort.oldest => -newest,
      JobSort.salaryHigh => byPay(_top(b), _top(a)),
      JobSort.salaryLow => byPay(_lowRank(a), _lowRank(b)),
    };
  }
}

/// A job title offered while typing, with how many jobs have it in the title.
class JobSuggestion {
  const JobSuggestion({required this.title, required this.count});

  final String title;
  final int count;
}

class JobSearch {
  const JobSearch._();

  /// Every word of [keyword] must appear somewhere in the job's title,
  /// company, place, type, level, requirements or description.
  static bool matches(JobPosting job, String keyword) {
    final words = keyword
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    final text = [
      job.title,
      job.companyName,
      job.location,
      job.employmentType,
      job.level,
      job.requirements,
      job.description,
    ].whereType<String>().join('\n').toLowerCase();
    return words.every(text.contains);
  }

  /// Up to [limit] distinct job titles containing [text], most common first.
  static List<JobSuggestion> suggest(
    List<JobPosting> jobs,
    String text, {
    int limit = JobConstants.suggestionLimit,
  }) {
    final needle = text.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    final lowered = [for (final job in jobs) job.title.toLowerCase()];
    final titles = <String, String>{};
    for (var i = 0; i < jobs.length; i++) {
      if (lowered[i].contains(needle)) {
        titles.putIfAbsent(lowered[i], () => jobs[i].title);
      }
    }
    final suggestions = [
      for (final entry in titles.entries)
        JobSuggestion(
          title: entry.value,
          count: lowered.where((title) => title.contains(entry.key)).length,
        ),
    ];
    suggestions.sort(
      (a, b) => a.count != b.count
          ? b.count.compareTo(a.count)
          : a.title.compareTo(b.title),
    );
    return suggestions.take(limit).toList();
  }
}
