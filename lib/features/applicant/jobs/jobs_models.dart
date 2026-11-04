import 'jobs_constants.dart';

/// A public job posting as a list card shows it. The description and the
/// requirements are kept only to be searched (a keyword finds a skill that
/// the requirements name); the benefits are left out, and the detail screen
/// loads every text of one job.
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
    this.description,
    this.requirements,
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
  final String? description;
  final String? requirements;
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
      description: _text(json['description']),
      requirements: _text(json['requirements']),
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
  const PublicJobs({required this.jobs, required this.total});

  /// Every open job: all the pages of the API were read.
  final List<JobPosting> jobs;

  /// How many open jobs the API reports in all.
  final int total;
}

/// A job with every text of its page.
class JobDetail {
  const JobDetail({required this.job, this.benefits});

  final JobPosting job;
  final String? benefits;

  factory JobDetail.fromJson(Map<String, dynamic> json) => JobDetail(
    job: JobPosting.fromJson(json),
    benefits: JobPosting._text(json['benefits']),
  );
}

/// The company of a job as its page shows it: what it does, how big it is and
/// how many jobs it has open.
class JobCompany {
  const JobCompany({
    required this.id,
    required this.name,
    this.industry,
    this.companySize,
    this.openRoleCount = 0,
  });

  final String id;
  final String name;
  final String? industry;

  /// A `company_size` value such as "51-200" or "1000+".
  final String? companySize;
  final int openRoleCount;

  factory JobCompany.fromJson(Map<String, dynamic> json) => JobCompany(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    industry: JobPosting._text(json['industry']),
    companySize: JobPosting._text(json['companySize']),
    openRoleCount: (json['openRoleCount'] as num?)?.toInt() ?? 0,
  );
}

/// What the signed-in applicant already did with a job: the latest of their
/// applications to it.
class JobApplication {
  const JobApplication({
    required this.id,
    required this.status,
    required this.canApplyAgain,
  });

  final String id;
  final String status;

  /// The API says when a closed application leaves room for a new one.
  final bool canApplyAgain;

  factory JobApplication.fromJson(Map<String, dynamic> json) => JobApplication(
    id: json['id'] as String? ?? '',
    status: json['status'] as String? ?? '',
    canApplyAgain: json['canApplyAgain'] as bool? ?? false,
  );
}
