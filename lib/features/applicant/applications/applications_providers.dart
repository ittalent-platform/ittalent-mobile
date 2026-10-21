import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/client.dart';
import 'applications_constants.dart';

class ApplicationItem {
  const ApplicationItem({
    required this.id,
    required this.jobTitle,
    required this.companyName,
    required this.status,
    required this.submittedAt,
    this.reviewStage,
    this.location,
    this.jobType,
    this.canWithdraw = false,
  });

  final String id;
  final String jobTitle;
  final String companyName;
  final String status;
  final DateTime? submittedAt;
  final String? reviewStage;
  final String? location;
  final String? jobType;
  final bool canWithdraw;

  factory ApplicationItem.fromJson(Map<String, dynamic> json) {
    final job = (json['job'] as Map<String, dynamic>?) ?? const {};
    return ApplicationItem(
      id: json['id'] as String? ?? '',
      jobTitle: job['title'] as String? ?? '',
      companyName: job['companyName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? ''),
      reviewStage: json['reviewStage'] as String?,
      location: job['location'] as String?,
      jobType: job['jobType'] as String?,
      canWithdraw: json['canWithdraw'] as bool? ?? false,
    );
  }
}

class ApplicationsPage {
  const ApplicationsPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.statusCounts,
  });

  final List<ApplicationItem> items;
  final int page;
  final int totalPages;
  final int total;
  final Map<String, int> statusCounts;

  factory ApplicationsPage.fromJson(Map<String, dynamic> json) {
    final counts = (json['statusCounts'] as Map<String, dynamic>?) ?? const {};
    return ApplicationsPage(
      items: ((json['items'] as List<dynamic>?) ?? const [])
          .map((e) => ApplicationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      statusCounts: counts.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }
}

/// Search, filter and sort criteria of My Applications (UC-S3-MYAPP-05).
class ApplicationsQuery {
  const ApplicationsQuery({
    this.search = '',
    this.statuses = const {},
    this.reviewStage,
    this.submittedFrom,
    this.submittedTo,
    this.sortOrder = ApplicationConstants.orderDescending,
  });

  final String search;
  final Set<String> statuses;
  final String? reviewStage;
  final DateTime? submittedFrom;
  final DateTime? submittedTo;
  final String sortOrder;

  bool get isFiltered =>
      search.isNotEmpty ||
      statuses.isNotEmpty ||
      reviewStage != null ||
      submittedFrom != null ||
      submittedTo != null;

  ApplicationsQuery copyWith({
    String? search,
    Set<String>? statuses,
    String? reviewStage,
    bool clearReviewStage = false,
    DateTime? submittedFrom,
    DateTime? submittedTo,
    bool clearDates = false,
    String? sortOrder,
  }) {
    return ApplicationsQuery(
      search: search ?? this.search,
      statuses: statuses ?? this.statuses,
      reviewStage: clearReviewStage ? null : reviewStage ?? this.reviewStage,
      submittedFrom: clearDates ? null : submittedFrom ?? this.submittedFrom,
      submittedTo: clearDates ? null : submittedTo ?? this.submittedTo,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// The API rejects unknown parameters, so only set criteria are sent.
  Map<String, dynamic> toQueryParameters({required int page}) {
    final keyword = search.trim();
    return {
      'page': page,
      'limit': ApplicationConstants.pageSize,
      'sortBy': ApplicationConstants.sortSubmittedAt,
      'sortOrder': sortOrder,
      if (keyword.isNotEmpty) 'search': keyword,
      if (statuses.isNotEmpty) 'status': statuses.join(','),
      if (reviewStage != null) 'reviewStage': reviewStage,
      if (submittedFrom != null)
        'submittedFrom': _startOfDay(submittedFrom!).toUtc().toIso8601String(),
      if (submittedTo != null)
        'submittedTo': _endOfDay(submittedTo!).toUtc().toIso8601String(),
    };
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
}

class ApplicationsQueryNotifier extends Notifier<ApplicationsQuery> {
  @override
  ApplicationsQuery build() => const ApplicationsQuery();

  // Replacing the query makes [myApplicationsProvider] reload from page 1.
  void update(ApplicationsQuery query) => state = query;

  void clear() => state = const ApplicationsQuery();
}

final applicationsQueryProvider =
    NotifierProvider.autoDispose<ApplicationsQueryNotifier, ApplicationsQuery>(
      ApplicationsQueryNotifier.new,
    );

class ApplicationsListState {
  const ApplicationsListState({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.statusCounts,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<ApplicationItem> items;
  final int page;
  final int totalPages;
  final int total;
  final Map<String, int> statusCounts;
  final bool loadingMore;
  final bool loadMoreFailed;

  bool get hasMore => page < totalPages;

  ApplicationsListState copyWith({
    List<ApplicationItem>? items,
    int? page,
    int? totalPages,
    bool? loadingMore,
    bool? loadMoreFailed,
  }) {
    return ApplicationsListState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total,
      statusCounts: statusCounts,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}

class MyApplicationsNotifier extends AsyncNotifier<ApplicationsListState> {
  @override
  Future<ApplicationsListState> build() async {
    final query = ref.watch(applicationsQueryProvider);
    final page = await _fetch(query, 1);
    return ApplicationsListState(
      items: page.items,
      page: page.page,
      totalPages: page.totalPages,
      total: page.total,
      statusCounts: page.statusCounts,
    );
  }

  Future<ApplicationsPage> _fetch(ApplicationsQuery query, int page) async {
    final response = await ref
        .read(apiClientProvider)
        .get<Map<String, dynamic>>(
          ApplicationConstants.listPath,
          queryParameters: query.toQueryParameters(page: page),
        );
    return ApplicationsPage.fromJson(response.data ?? const {});
  }

  /// Appends the next page; a failure keeps what is already shown (E4).
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(
      current.copyWith(loadingMore: true, loadMoreFailed: false),
    );
    try {
      final next = await _fetch(
        ref.read(applicationsQueryProvider),
        current.page + 1,
      );
      final known = current.items.map((e) => e.id).toSet();
      state = AsyncData(
        current.copyWith(
          items: [
            ...current.items,
            ...next.items.where((e) => !known.contains(e.id)),
          ],
          page: next.page,
          totalPages: next.totalPages,
          loadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(loadingMore: false, loadMoreFailed: true),
      );
    }
  }
}

final myApplicationsProvider =
    AsyncNotifierProvider.autoDispose<
      MyApplicationsNotifier,
      ApplicationsListState
    >(MyApplicationsNotifier.new);

class ApplicationAttachment {
  const ApplicationAttachment({required this.type, required this.fileName});

  final String type;
  final String fileName;

  factory ApplicationAttachment.fromJson(Map<String, dynamic> json) =>
      ApplicationAttachment(
        type: json['type'] as String? ?? '',
        fileName: json['fileName'] as String? ?? '',
      );
}

/// A certificate as it was when the application was sent; later edits do not change it.
class ApplicationCertificate {
  const ApplicationCertificate({
    required this.name,
    required this.url,
    this.issuer,
    this.issuedDate,
    this.expiryDate,
  });

  final String name;
  final String url;
  final String? issuer;
  final String? issuedDate;
  final String? expiryDate;

  factory ApplicationCertificate.fromJson(Map<String, dynamic> json) =>
      ApplicationCertificate(
        name: json['name'] as String? ?? '',
        url: json['url'] as String? ?? '',
        issuer: json['issuer'] as String?,
        issuedDate: json['issuedDate'] as String?,
        expiryDate: json['expiryDate'] as String?,
      );
}

class ApplicationDetail {
  const ApplicationDetail({
    required this.summary,
    required this.version,
    required this.attachments,
    required this.certificates,
    this.message,
    this.withdrawalReason,
    this.latestStatusAt,
  });

  final ApplicationItem summary;
  final int version;
  final List<ApplicationAttachment> attachments;
  final List<ApplicationCertificate> certificates;
  final String? message;
  final String? withdrawalReason;
  final DateTime? latestStatusAt;

  factory ApplicationDetail.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) =>
        ((json[key] as List<dynamic>?) ?? const [])
            .map((e) => parse(e as Map<String, dynamic>))
            .toList();
    return ApplicationDetail(
      summary: ApplicationItem.fromJson(json),
      version: json['version'] as int? ?? 0,
      attachments: list('attachments', ApplicationAttachment.fromJson),
      certificates: list('certificates', ApplicationCertificate.fromJson),
      message: json['message'] as String?,
      withdrawalReason: json['withdrawalReason'] as String?,
      latestStatusAt: DateTime.tryParse(
        json['latestStatusAt'] as String? ?? '',
      ),
    );
  }
}

final applicationDetailProvider = FutureProvider.autoDispose
    .family<ApplicationDetail, String>((ref, id) async {
      final response = await ref
          .watch(apiClientProvider)
          .get<Map<String, dynamic>>(ApplicationConstants.detailPath(id));
      return ApplicationDetail.fromJson(response.data ?? const {});
    });

class ApplicationHistoryEntry {
  const ApplicationHistoryEntry({
    required this.status,
    required this.actorRole,
    required this.occurredAt,
    this.reviewStage,
  });

  final String status;
  final String actorRole;
  final DateTime? occurredAt;
  final String? reviewStage;

  factory ApplicationHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ApplicationHistoryEntry(
        status: json['status'] as String? ?? '',
        actorRole: json['actorRole'] as String? ?? '',
        occurredAt: DateTime.tryParse(json['occurredAt'] as String? ?? ''),
        reviewStage: json['reviewStage'] as String?,
      );
}

/// Every history entry in chronological order (UC-S3-MYAPP-03); histories are short,
/// so pages are read until the last one.
final applicationHistoryProvider = FutureProvider.autoDispose
    .family<List<ApplicationHistoryEntry>, String>((ref, id) async {
      final client = ref.watch(apiClientProvider);
      final entries = <ApplicationHistoryEntry>[];
      var page = 1;
      var totalPages = 1;
      while (page <= totalPages) {
        final response = await client.get<Map<String, dynamic>>(
          ApplicationConstants.historyPath(id),
          queryParameters: {
            'page': page,
            'limit': ApplicationConstants.historyPageSize,
          },
        );
        final data = response.data ?? const {};
        entries.addAll(
          ((data['items'] as List<dynamic>?) ?? const []).map(
            (e) => ApplicationHistoryEntry.fromJson(e as Map<String, dynamic>),
          ),
        );
        totalPages = data['totalPages'] as int? ?? 1;
        page++;
      }
      return entries;
    });
