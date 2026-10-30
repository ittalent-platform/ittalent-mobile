import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/client.dart';
import 'portfolio_constants.dart';

class PortfolioLink {
  const PortfolioLink({
    required this.id,
    required this.title,
    required this.url,
    required this.version,
    this.description,
  });

  final String id;
  final String title;
  final String url;
  final int version;
  final String? description;

  /// Host without "www.", shown instead of the full link.
  String get domain {
    final host = Uri.tryParse(url)?.host ?? '';
    if (host.isEmpty) return url;
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  bool get isHttps => url.startsWith('https://');

  factory PortfolioLink.fromJson(Map<String, dynamic> json) => PortfolioLink(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    url: json['url'] as String? ?? '',
    version: json['version'] as int? ?? 1,
    description: json['description'] as String?,
  );
}

class PortfolioListState {
  const PortfolioListState({
    required this.items,
    required this.page,
    required this.totalPages,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<PortfolioLink> items;
  final int page;
  final int totalPages;
  final bool loadingMore;
  final bool loadMoreFailed;

  bool get hasMore => page < totalPages;

  PortfolioListState copyWith({
    List<PortfolioLink>? items,
    int? page,
    int? totalPages,
    bool? loadingMore,
    bool? loadMoreFailed,
  }) => PortfolioListState(
    items: items ?? this.items,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

class PortfolioNotifier extends AsyncNotifier<PortfolioListState> {
  @override
  Future<PortfolioListState> build() async {
    final first = await _fetch(1);
    return PortfolioListState(
      items: first.items,
      page: first.page,
      totalPages: first.totalPages,
    );
  }

  Future<({List<PortfolioLink> items, int page, int totalPages})> _fetch(
    int page,
  ) async {
    final response = await ref
        .read(apiClientProvider)
        .get<Map<String, dynamic>>(
          PortfolioConstants.listPath,
          queryParameters: {'page': page, 'limit': PortfolioConstants.pageSize},
        );
    final data = response.data ?? const {};
    return (
      items: ((data['items'] as List<dynamic>?) ?? const [])
          .map((e) => PortfolioLink.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: data['page'] as int? ?? page,
      totalPages: data['totalPages'] as int? ?? 0,
    );
  }

  /// Appends the next page; a failure keeps what is already shown.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(
      current.copyWith(loadingMore: true, loadMoreFailed: false),
    );
    try {
      final next = await _fetch(current.page + 1);
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

final portfolioProvider =
    AsyncNotifierProvider.autoDispose<PortfolioNotifier, PortfolioListState>(
      PortfolioNotifier.new,
    );

/// Writes on the Candidate's portfolio. Every success refreshes the list.
class PortfolioActions {
  PortfolioActions(this._ref);

  final Ref _ref;

  /// UC-S4-PORT-01. Reusing [idempotencyKey] for a retry returns the committed link.
  Future<PortfolioLink> create({
    required String idempotencyKey,
    required String title,
    required String url,
    String? description,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .post<Map<String, dynamic>>(
          PortfolioConstants.listPath,
          data: {'title': title, 'url': url, 'description': ?description},
          options: Options(
            headers: {PortfolioConstants.idempotencyHeader: idempotencyKey},
          ),
        );
    _ref.invalidate(portfolioProvider);
    return PortfolioLink.fromJson(response.data ?? const {});
  }

  /// UC-S4-PORT-02. Only changed fields are sent; the server owns versioning.
  Future<PortfolioLink> update({
    required PortfolioLink current,
    required Map<String, Object?> changes,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .patch<Map<String, dynamic>>(
          PortfolioConstants.itemPath(current.id),
          data: {'expectedVersion': current.version, ...changes},
        );
    _ref.invalidate(portfolioProvider);
    return PortfolioLink.fromJson(response.data ?? const {});
  }

  /// UC-S4-PORT-03. Only the platform's reference goes, never the page it points to.
  Future<void> delete(PortfolioLink link) async {
    await _ref
        .read(apiClientProvider)
        .delete<void>(
          PortfolioConstants.itemPath(link.id),
          queryParameters: {'expectedVersion': link.version},
        );
    _ref.invalidate(portfolioProvider);
  }
}

final portfolioActionsProvider = Provider<PortfolioActions>(
  PortfolioActions.new,
);
