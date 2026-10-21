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
    this.canApplyAgain = false,
    this.latestStatusAt,
    this.withdrawnAt,
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
  final bool canApplyAgain;
  final DateTime? latestStatusAt;
  final DateTime? withdrawnAt;

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
      canApplyAgain: json['canApplyAgain'] as bool? ?? false,
      latestStatusAt: DateTime.tryParse(
        json['latestStatusAt'] as String? ?? '',
      ),
      withdrawnAt: DateTime.tryParse(json['withdrawnAt'] as String? ?? ''),
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

/// Status counts for a search and "submitted from" date, ignoring the status
/// filter, so the filter sheet can show "Show N results" before applying.
final applicationStatusCountsProvider = FutureProvider.autoDispose
    .family<Map<String, int>, ({String search, DateTime? submittedFrom})>((
      ref,
      key,
    ) async {
      final query = ApplicationsQuery(
        search: key.search,
        submittedFrom: key.submittedFrom,
      );
      final response = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>(
            ApplicationConstants.listPath,
            queryParameters: {...query.toQueryParameters(page: 1), 'limit': 1},
          );
      return ApplicationsPage.fromJson(response.data ?? const {}).statusCounts;
    });
