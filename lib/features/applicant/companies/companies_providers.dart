import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/client.dart';
import 'companies_constants.dart';
import 'companies_models.dart';

/// Search and filters of the company list (UC-BENT-03).
class CompaniesQuery {
  const CompaniesQuery({
    this.search = '',
    this.industries = const {},
    this.sizes = const {},
    this.city,
  });

  final String search;
  final Set<String> industries;
  final Set<String> sizes;
  final String? city;

  /// How many of the three filters are set (the search is not one of them).
  int get filterCount =>
      (industries.isEmpty ? 0 : 1) +
      (sizes.isEmpty ? 0 : 1) +
      (city == null ? 0 : 1);

  bool get isFiltered => search.isNotEmpty || filterCount > 0;

  CompaniesQuery copyWith({
    String? search,
    Set<String>? industries,
    Set<String>? sizes,
    String? city,
    bool clearCity = false,
  }) {
    return CompaniesQuery(
      search: search ?? this.search,
      industries: industries ?? this.industries,
      sizes: sizes ?? this.sizes,
      city: clearCity ? null : city ?? this.city,
    );
  }

  /// The API rejects unknown and empty parameters, so only set criteria are
  /// sent. `industry` and `company_size` take a comma-separated list.
  Map<String, dynamic> toQueryParameters({
    required int page,
    int limit = CompanyConstants.pageSize,
  }) {
    final keyword = search.trim();
    return {
      'page': page,
      'limit': limit,
      if (keyword.isNotEmpty) 'keyword': keyword,
      if (industries.isNotEmpty) 'industry': industries.join(','),
      if (sizes.isNotEmpty) 'company_size': sizes.join(','),
      if (city != null) 'location': city,
    };
  }

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  bool operator ==(Object other) =>
      other is CompaniesQuery &&
      other.search == search &&
      other.city == city &&
      _sameSet(other.industries, industries) &&
      _sameSet(other.sizes, sizes);

  @override
  int get hashCode => Object.hash(
    search,
    city,
    Object.hashAllUnordered(industries),
    Object.hashAllUnordered(sizes),
  );
}

class CompaniesQueryNotifier extends Notifier<CompaniesQuery> {
  @override
  CompaniesQuery build() => const CompaniesQuery();

  // Replacing the query makes [companiesProvider] reload from page 1.
  void update(CompaniesQuery query) => state = query;

  void clear() => state = const CompaniesQuery();
}

final companiesQueryProvider =
    NotifierProvider.autoDispose<CompaniesQueryNotifier, CompaniesQuery>(
      CompaniesQueryNotifier.new,
    );

class CompaniesListState {
  const CompaniesListState({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<CompanySummary> items;
  final int page;
  final int totalPages;
  final int total;
  final bool loadingMore;
  final bool loadMoreFailed;

  bool get hasMore => page < totalPages;

  CompaniesListState copyWith({
    List<CompanySummary>? items,
    int? page,
    int? totalPages,
    bool? loadingMore,
    bool? loadMoreFailed,
  }) {
    return CompaniesListState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}

class CompaniesNotifier extends AsyncNotifier<CompaniesListState> {
  @override
  Future<CompaniesListState> build() async {
    final query = ref.watch(companiesQueryProvider);
    final page = await _fetch(query, 1);
    return CompaniesListState(
      items: page.items,
      page: page.page,
      totalPages: page.totalPages,
      total: page.total,
    );
  }

  Future<CompaniesPage> _fetch(CompaniesQuery query, int page) async {
    final response = await ref
        .read(apiClientProvider)
        .get<Map<String, dynamic>>(
          CompanyConstants.listPath,
          queryParameters: query.toQueryParameters(page: page),
        );
    return CompaniesPage.fromJson(response.data ?? const {});
  }

  /// Appends the next page; a failure keeps what is already shown. After a
  /// failure scrolling does not ask again: only the retry button ([retry]).
  Future<void> loadMore({bool retry = false}) async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;
    if (current.loadMoreFailed && !retry) return;
    final query = ref.read(companiesQueryProvider);
    final loading = current.copyWith(loadingMore: true, loadMoreFailed: false);
    state = AsyncData(loading);

    // The user searched, filtered or refreshed meanwhile: the answer is for a
    // list that is no longer on show.
    bool stale() =>
        !ref.mounted ||
        ref.read(companiesQueryProvider) != query ||
        !identical(state.value, loading);

    try {
      final next = await _fetch(query, current.page + 1);
      if (stale()) return;
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
          loadMoreFailed: false,
        ),
      );
    } catch (_) {
      if (stale()) return;
      state = AsyncData(
        current.copyWith(loadingMore: false, loadMoreFailed: true),
      );
    }
  }
}

/// A failure is shown at once, with a retry button: Riverpod's automatic retry
/// is off, or the skeleton would stay for a minute before the error appears.
final companiesProvider =
    AsyncNotifierProvider.autoDispose<CompaniesNotifier, CompaniesListState>(
      CompaniesNotifier.new,
      retry: (_, _) => null,
    );

/// How many companies a search and filters match, so the filter sheet can
/// show "Show N companies" before they are applied.
final companiesCountProvider = FutureProvider.autoDispose
    .family<int, CompaniesQuery>((ref, query) async {
      final response = await ref
          .watch(apiClientProvider)
          .get<Map<String, dynamic>>(
            CompanyConstants.listPath,
            queryParameters: query.toQueryParameters(page: 1, limit: 1),
          );
      return CompaniesPage.fromJson(response.data ?? const {}).total;
    }, retry: (_, _) => null);

/// The industries a company can be filtered by, biggest first.
final companyIndustriesProvider =
    FutureProvider.autoDispose<List<IndustryOption>>(retry: (_, _) => null, (
      ref,
    ) async {
      final response = await ref
          .watch(apiClientProvider)
          .get<Map<String, dynamic>>(CompanyConstants.industriesPath);
      return ((response.data?['items'] as List<dynamic>?) ?? const [])
          .map((e) => IndustryOption.fromJson(e as Map<String, dynamic>))
          .where((e) => e.industry.isNotEmpty)
          .toList();
    });

/// The company page. A company that is missing, suspended or removed answers
/// 404, and the screen says it is not available.
final companyDetailProvider = FutureProvider.autoDispose
    .family<CompanyDetail, String>((ref, id) async {
      final response = await ref
          .watch(apiClientProvider)
          .get<Map<String, dynamic>>(CompanyConstants.detailPath(id));
      return CompanyDetail.fromJson(response.data ?? const {});
    }, retry: (_, _) => null);

/// One page of the open jobs of a company. The Jobs tab shows pages 1…n, and
/// "Load more" asks for the next one.
final companyJobsPageProvider = FutureProvider.autoDispose
    .family<CompanyJobsPage, ({String companyId, int page})>((ref, key) async {
      final response = await ref
          .watch(apiClientProvider)
          .get<Map<String, dynamic>>(
            CompanyConstants.jobsPath,
            queryParameters: {
              'enterprise_id': key.companyId,
              'page': key.page,
              'limit': CompanyConstants.jobsPageSize,
            },
          );
      return CompanyJobsPage.fromJson(response.data ?? const {});
    }, retry: (_, _) => null);
