import 'package:flutter/foundation.dart';

@immutable
class SavedJobEnterprise {
  const SavedJobEnterprise({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String? logoUrl;

  factory SavedJobEnterprise.fromJson(Map<String, dynamic> json) {
    return SavedJobEnterprise(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (logoUrl != null) 'logoUrl': logoUrl,
  };
}

@immutable
class SavedJobItem {
  const SavedJobItem({
    required this.id,
    required this.jobId,
    required this.savedAt,
    this.availability = 'available',
    this.isClosingSoon = false,
    this.title,
    this.slug,
    this.enterprise,
    this.location,
    this.employmentType,
    this.level,
    this.salaryMin,
    this.salaryMax,
    this.salaryNegotiable = false,
    this.currency = 'VND',
    this.expiresAt,
  });

  final String id;
  final String jobId;
  final DateTime savedAt;
  final String availability;
  final bool isClosingSoon;
  final String? title;
  final String? slug;
  final SavedJobEnterprise? enterprise;
  final String? location;
  final String? employmentType;
  final String? level;
  final num? salaryMin;
  final num? salaryMax;
  final bool salaryNegotiable;
  final String currency;
  final DateTime? expiresAt;

  bool get isAvailable => availability == 'available';
  bool get isUnavailable => availability == 'unavailable';

  bool get hasSalary =>
      !salaryNegotiable && ((salaryMin ?? 0) > 0 || (salaryMax ?? 0) > 0);

  factory SavedJobItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final rawEnterprise = json['enterprise'];
    final enterprise =
        rawEnterprise is Map<String, dynamic>
            ? SavedJobEnterprise.fromJson(rawEnterprise)
            : null;

    final rawExpiresAt = json['expiresAt'];
    final expiresAt =
        rawExpiresAt is String ? DateTime.tryParse(rawExpiresAt) : null;

    return SavedJobItem(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      jobId: json['jobId'] as String? ?? '',
      savedAt: parseDate(json['savedAt']),
      availability: json['availability'] as String? ?? 'available',
      isClosingSoon: json['isClosingSoon'] == true,
      title: json['title'] as String?,
      slug: json['slug'] as String?,
      enterprise: enterprise,
      location: json['location'] as String?,
      employmentType: json['employmentType'] as String?,
      level: json['level'] as String?,
      salaryMin: json['salaryMin'] as num?,
      salaryMax: json['salaryMax'] as num?,
      salaryNegotiable: json['salaryNegotiable'] == true,
      currency: json['currency'] as String? ?? 'VND',
      expiresAt: expiresAt,
    );
  }
}

@immutable
class SavedJobsCounts {
  const SavedJobsCounts({
    this.all = 0,
    this.available = 0,
    this.unavailable = 0,
  });

  final int all;
  final int available;
  final int unavailable;

  SavedJobsCounts copyWith({int? all, int? available, int? unavailable}) {
    return SavedJobsCounts(
      all: all ?? this.all,
      available: available ?? this.available,
      unavailable: unavailable ?? this.unavailable,
    );
  }
}

const Object _unspecified = Object();

@immutable
class SavedJobsQuery {
  const SavedJobsQuery({
    this.status = 'all',
    this.q,
    this.page = 1,
    this.limit = 20,
  });

  final String status;
  final String? q;
  final int page;
  final int limit;

  Map<String, dynamic> toQueryParams() {
    final query = <String, dynamic>{
      'status': status,
      'page': page,
      'limit': limit,
    };
    final trimmed = q?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      query['q'] = trimmed;
    }
    return query;
  }

  SavedJobsQuery copyWith({
    String? status,
    Object? q = _unspecified,
    int? page,
    int? limit,
    bool clearQuery = false,
  }) {
    final newQ = clearQuery
        ? null
        : (identical(q, _unspecified) ? this.q : q as String?);
    return SavedJobsQuery(
      status: status ?? this.status,
      q: newQ,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

@immutable
class SavedJobsResponse {
  const SavedJobsResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  final List<SavedJobItem> items;
  final int total;
  final int page;
  final int totalPages;

  factory SavedJobsResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const [];
    return SavedJobsResponse(
      items:
          rawItems
              .whereType<Map<String, dynamic>>()
              .map(SavedJobItem.fromJson)
              .toList(growable: false),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
