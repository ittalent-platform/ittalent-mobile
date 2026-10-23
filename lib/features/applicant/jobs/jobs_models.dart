import 'jobs_constants.dart';

/// A public job posting as the marketplace shows it.
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
    this.description,
    this.requirements,
    this.benefits,
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
  final String? description;
  final String? requirements;
  final String? benefits;
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
      description: _text(json['description']),
      requirements: _text(json['requirements']),
      benefits: _text(json['benefits']),
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

  /// A salary is shown only when it is not negotiable and has an amount.
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
  const JobsPage({required this.items, required this.totalPages});

  final List<JobPosting> items;
  final int totalPages;

  factory JobsPage.fromJson(Map<String, dynamic> json) => JobsPage(
    items: ((json['items'] as List<dynamic>?) ?? const [])
        .map((e) => JobPosting.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalPages: json['totalPages'] as int? ?? 0,
  );
}
