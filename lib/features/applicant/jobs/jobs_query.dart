import 'jobs_constants.dart';
import 'jobs_models.dart';

enum JobSort { newest, oldest, salaryHigh, salaryLow }

/// What the job list is narrowed and ordered by. The API cannot filter by
/// most of these, so they are applied to the jobs already read (see
/// `publicJobsProvider`), which also gives live counts without a request.
class JobsQuery {
  const JobsQuery({
    this.search = '',
    this.types = const {},
    this.levels = const {},
    this.cities = const {},
    this.salaryMin,
    this.salaryMax,
    this.includeNegotiable = true,
    this.sort = JobSort.newest,
  });

  final String search;

  /// Employment types as the API stores them ("Full-time").
  final Set<String> types;

  /// Lower-cased levels ("senior").
  final Set<String> levels;

  /// Names matched inside the location of a job ("Ho Chi Minh").
  final Set<String> cities;

  /// The salary range, in millions of VND a month; either end may be open.
  final int? salaryMin;
  final int? salaryMax;

  /// Whether a job without a salary amount (negotiable, or not in VND) stays
  /// in the list while a salary range is set.
  final bool includeNegotiable;
  final JobSort sort;

  bool get hasSalaryRange => salaryMin != null || salaryMax != null;

  /// How many criteria narrow the list: the keyword, each chosen type, level
  /// and city, and the salary range. These are the chips of the list header.
  int get filterCount =>
      (search.trim().isEmpty ? 0 : 1) +
      types.length +
      levels.length +
      cities.length +
      (hasSalaryRange ? 1 : 0);

  /// Sorting does not narrow the list, so it is not a filter.
  bool get isFiltered => filterCount > 0;

  /// The range is empty when its minimum is above its maximum.
  bool get hasValidSalaryRange =>
      salaryMin == null || salaryMax == null || salaryMin! <= salaryMax!;

  JobsQuery copyWith({
    String? search,
    Set<String>? types,
    Set<String>? levels,
    Set<String>? cities,
    int? salaryMin,
    int? salaryMax,
    bool clearSalary = false,
    bool? includeNegotiable,
    JobSort? sort,
  }) => JobsQuery(
    search: search ?? this.search,
    types: types ?? this.types,
    levels: levels ?? this.levels,
    cities: cities ?? this.cities,
    salaryMin: clearSalary ? null : salaryMin ?? this.salaryMin,
    salaryMax: clearSalary ? null : salaryMax ?? this.salaryMax,
    includeNegotiable: includeNegotiable ?? this.includeNegotiable,
    sort: sort ?? this.sort,
  );

  /// Drops every filter and keeps the sort order, as on the web.
  JobsQuery cleared() => JobsQuery(sort: sort);

  /// The matching jobs in the chosen order.
  List<JobPosting> apply(List<JobPosting> jobs) {
    final keyword = search.trim();
    final matching = [
      for (final job in jobs)
        if (_matches(job, keyword)) job,
    ];
    matching.sort(_compare);
    return matching;
  }

  bool _matches(JobPosting job, String keyword) {
    if (keyword.isNotEmpty && !JobSearch.matches(job, keyword)) return false;
    if (types.isNotEmpty && !types.contains(job.employmentType)) return false;
    if (levels.isNotEmpty && !levels.contains(job.level?.toLowerCase())) {
      return false;
    }
    if (cities.isNotEmpty && !_inCity(job)) return false;
    return !hasSalaryRange || _inSalaryRange(job);
  }

  bool _inCity(JobPosting job) {
    final place = JobSearch.fold(job.location ?? '');
    return cities.any((city) => place.contains(JobSearch.fold(city)));
  }

  /// A job is in the range when its own range overlaps it. A job with a
  /// missing end is open on that side. Only salaries in VND can be compared
  /// with a range in VND, so another currency counts as "no amount".
  bool _inSalaryRange(JobPosting job) {
    if (!job.hasSalary || job.currency != JobConstants.currencyVnd) {
      return includeNegotiable;
    }
    final low = (job.salaryMin ?? 0) / JobConstants.vndPerMillion;
    final highRaw = job.salaryMax ?? 0;
    final high = highRaw > 0
        ? highRaw / JobConstants.vndPerMillion
        : double.infinity;
    if (salaryMin != null && high < salaryMin!) return false;
    if (salaryMax != null && low > salaryMax!) return false;
    return true;
  }

  /// The best salary of a job, 0 when it has none. Amounts in another
  /// currency cannot be ranked against VND, so they count as none.
  static num _top(JobPosting job) =>
      !job.hasSalary || job.currency != JobConstants.currencyVnd
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

  /// Vietnamese letters and the plain letter each one stands for.
  static const Map<String, String> _plain = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };

  static final Map<String, String> _fold = {
    for (final entry in _plain.entries)
      for (final letter in entry.value.split('')) letter: entry.key,
  };

  /// Lower-case text without Vietnamese accents, one character for each
  /// character of [text], so "Hà Nội" and "ha noi" are the same place and a
  /// position found in the folded text is also one in the original.
  static String fold(String text) {
    final lower = text.toLowerCase();
    final out = StringBuffer();
    for (final rune in lower.split('')) {
      out.write(_fold[rune] ?? rune);
    }
    return out.toString();
  }

  /// What a keyword is looked for in, folded once for each job.
  static final Expando<String> _texts = Expando<String>('jobSearchText');

  static String _textOf(JobPosting job) => _texts[job] ??= fold(
    [
      job.title,
      job.companyName,
      job.location,
      job.employmentType,
      job.level,
      job.requirements,
      job.description,
    ].whereType<String>().join('\n'),
  );

  /// Every word of [keyword] must appear somewhere in the job's title,
  /// company, place, type, level, requirements or description.
  static bool matches(JobPosting job, String keyword) {
    final words = fold(keyword)
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    final text = _textOf(job);
    return words.every(text.contains);
  }

  /// Up to [limit] distinct job titles containing [text], most common first.
  static List<JobSuggestion> suggest(
    List<JobPosting> jobs,
    String text, {
    int limit = JobConstants.suggestionLimit,
  }) {
    final needle = fold(text.trim());
    if (needle.isEmpty) return const [];
    final folded = [for (final job in jobs) fold(job.title)];
    final titles = <String, String>{};
    for (var i = 0; i < jobs.length; i++) {
      if (folded[i].contains(needle)) {
        titles.putIfAbsent(folded[i], () => jobs[i].title);
      }
    }
    final suggestions = [
      for (final entry in titles.entries)
        JobSuggestion(
          title: entry.value,
          count: folded.where((title) => title.contains(entry.key)).length,
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
