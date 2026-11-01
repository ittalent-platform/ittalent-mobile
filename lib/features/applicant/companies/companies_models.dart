import 'companies_constants.dart';

/// Blank strings count as missing.
String? _text(Object? value) {
  final text = value is String ? value.trim() : '';
  return text.isEmpty ? null : text;
}

List<String> _texts(Object? value) => value is List
    ? [
        for (final item in value)
          if (_text(item) != null) _text(item)!,
      ]
    : const [];

/// A company as a list card shows it. The API sends public profile content
/// only: no contact, tax or registration data.
class CompanySummary {
  const CompanySummary({
    required this.id,
    required this.name,
    this.industry,
    this.companySize,
    this.shortDescription,
    this.cities = const [],
    this.openRoleCount = 0,
  });

  final String id;
  final String name;
  final String? industry;

  /// A `company_size` value such as "51-200" or "1000+".
  final String? companySize;
  final String? shortDescription;
  final List<String> cities;
  final int openRoleCount;

  factory CompanySummary.fromJson(Map<String, dynamic> json) => CompanySummary(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    industry: _text(json['industry']),
    companySize: _text(json['companySize']),
    shortDescription: _text(json['shortDescription']),
    cities: _texts(json['cities']),
    openRoleCount: (json['openRoleCount'] as num?)?.toInt() ?? 0,
  );
}

/// One page of `GET /enterprises/public`.
class CompaniesPage {
  const CompaniesPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<CompanySummary> items;
  final int page;
  final int totalPages;
  final int total;

  factory CompaniesPage.fromJson(Map<String, dynamic> json) => CompaniesPage(
    items: ((json['items'] as List<dynamic>?) ?? const [])
        .map((e) => CompanySummary.fromJson(e as Map<String, dynamic>))
        .toList(),
    page: json['page'] as int? ?? 1,
    totalPages: json['totalPages'] as int? ?? 0,
    total: json['total'] as int? ?? 0,
  );
}

/// An industry of the filter, with how many companies are in it.
class IndustryOption {
  const IndustryOption({required this.industry, required this.count});

  final String industry;
  final int count;

  factory IndustryOption.fromJson(Map<String, dynamic> json) => IndustryOption(
    industry: json['industry'] as String? ?? '',
    count: (json['count'] as num?)?.toInt() ?? 0,
  );
}

/// The company page (`GET /enterprises/{id}/public`). Only what the page
/// shows is kept.
class CompanyDetail {
  const CompanyDetail({
    required this.summary,
    this.description,
    this.headquarters,
    this.website,
    this.techStack = const [],
    this.benefits = const [],
  });

  final CompanySummary summary;
  final String? description;

  /// City of the head office.
  final String? headquarters;
  final String? website;
  final List<String> techStack;
  final List<String> benefits;

  String get id => summary.id;
  String get name => summary.name;

  factory CompanyDetail.fromJson(Map<String, dynamic> json) {
    final headquarters = json['headquarters'];
    return CompanyDetail(
      summary: CompanySummary.fromJson(json),
      description: _text(json['description']),
      headquarters: headquarters is Map<String, dynamic>
          ? _text(headquarters['city'])
          : null,
      website: _text(json['website']),
      techStack: _texts(json['techStack']),
      benefits: _texts(json['benefits']),
    );
  }
}

/// An open job in the Jobs tab of a company page.
class CompanyJob {
  const CompanyJob({
    required this.id,
    required this.title,
    this.location,
    this.level,
    this.salaryMin,
    this.salaryMax,
    this.salaryNegotiable = false,
    this.currency = CompanyConstants.currencyVnd,
    this.expiresAt,
  });

  final String id;
  final String title;
  final String? location;
  final String? level;
  final num? salaryMin;
  final num? salaryMax;
  final bool salaryNegotiable;
  final String currency;
  final DateTime? expiresAt;

  factory CompanyJob.fromJson(Map<String, dynamic> json) => CompanyJob(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    location: _text(json['location']),
    level: _text(json['level']),
    salaryMin: json['salaryMin'] as num?,
    salaryMax: json['salaryMax'] as num?,
    salaryNegotiable: json['salaryNegotiable'] as bool? ?? false,
    currency: _text(json['currency']) ?? CompanyConstants.currencyVnd,
    expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
  );

  /// An amount is shown only when the salary is not negotiable and has one. A
  /// job can also have no salary at all: it then shows neither an amount nor
  /// "Negotiable" (that word is for `salaryNegotiable` jobs only).
  bool get hasSalary =>
      !salaryNegotiable && ((salaryMin ?? 0) > 0 || (salaryMax ?? 0) > 0);
}

/// One page of `GET /job-postings` for one company.
class CompanyJobsPage {
  const CompanyJobsPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<CompanyJob> items;
  final int page;
  final int totalPages;
  final int total;

  bool get hasMore => page < totalPages;

  factory CompanyJobsPage.fromJson(Map<String, dynamic> json) =>
      CompanyJobsPage(
        items: ((json['items'] as List<dynamic>?) ?? const [])
            .map((e) => CompanyJob.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: json['page'] as int? ?? 1,
        totalPages: json['totalPages'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
      );
}
