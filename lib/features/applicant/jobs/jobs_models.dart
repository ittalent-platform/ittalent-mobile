import 'jobs_constants.dart';

/// A public job posting as a list card shows it. The long texts of a job
/// (description, requirements, benefits) are left out on purpose: the list
/// carries up to 2,000 jobs, and the detail screen loads them for one job.
class JobPosting {
  const JobPosting({
    required this.id,
    required this.title,
    required this.companyId,
    required this.companyName,
    this.location,
    this.employmentType,
    this.level,
    this.salaryMin,
    this.salaryMax,
    this.salaryNegotiable = false,
    this.currency = JobConstants.currencyVnd,
    this.openings,
    this.expiresAt,
    this.createdAt,
  });

  final String id;
  final String title;
  final String companyId;
  final String companyName;
  final String? location;
  final String? employmentType;
  final String? level;
  final num? salaryMin;
  final num? salaryMax;
  final bool salaryNegotiable;
  final String currency;
  final int? openings;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  factory JobPosting.fromJson(Map<String, dynamic> json) {
    final enterprise =
        (json['enterprise'] as Map<String, dynamic>?) ?? const {};
    return JobPosting(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      companyId:
          json['enterpriseId'] as String? ?? enterprise['id'] as String? ?? '',
      companyName: enterprise['name'] as String? ?? '',
      location: _text(json['location']),
      employmentType: _text(json['employmentType']),
      level: _text(json['level']),
      salaryMin: json['salaryMin'] as num?,
      salaryMax: json['salaryMax'] as num?,
      salaryNegotiable: json['salaryNegotiable'] as bool? ?? false,
      currency: _text(json['currency']) ?? JobConstants.currencyVnd,
      openings: (json['openings'] as num?)?.toInt(),
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  /// Blank strings count as missing.
  static String? _text(Object? value) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? null : text;
  }

  /// An amount is shown only when the salary is not negotiable and has one.
  /// A job can also have no salary at all: it then shows neither an amount nor
  /// "Negotiable" (that word is for `salaryNegotiable` jobs only).
  bool get hasSalary =>
      !salaryNegotiable && ((salaryMin ?? 0) > 0 || (salaryMax ?? 0) > 0);

  /// The API lists only open jobs; this guards against one closing meanwhile.
  bool isOpen(DateTime now) => expiresAt == null || !expiresAt!.isBefore(now);

  bool isNew(DateTime now) =>
      createdAt != null &&
      now.difference(createdAt!) <
          const Duration(days: JobConstants.newBadgeDays);

  /// Newest first. A job without a date goes last, and jobs of the same moment
  /// keep one fixed order (by id), so a list never reshuffles between reads.
  static int newestFirst(JobPosting a, JobPosting b) {
    final byDate = _millis(b).compareTo(_millis(a));
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  }

  static int _millis(JobPosting job) =>
      job.createdAt?.millisecondsSinceEpoch ?? 0;
}

/// One page of `GET /job-postings`.
class JobsPage {
  const JobsPage({
    required this.items,
    required this.total,
    required this.totalPages,
  });

  final List<JobPosting> items;
  final int total;
  final int totalPages;

  factory JobsPage.fromJson(Map<String, dynamic> json) => JobsPage(
    items: ((json['items'] as List<dynamic>?) ?? const [])
        .map((e) => JobPosting.fromJson(e as Map<String, dynamic>))
        .toList(),
    total: json['total'] as int? ?? 0,
    totalPages: json['totalPages'] as int? ?? 0,
  );
}

/// The open jobs the app could read, newest first.
class PublicJobs {
  const PublicJobs({
    required this.jobs,
    required this.total,
    required this.isPartial,
  });

  final List<JobPosting> jobs;

  /// How many open jobs the API reports in all.
  final int total;

  /// True when the market has more pages than the app reads
  /// (`JobConstants.maxPages`): [jobs] then holds only the newest ones, and
  /// the screen must not say that every job was seen.
  final bool isPartial;
}
