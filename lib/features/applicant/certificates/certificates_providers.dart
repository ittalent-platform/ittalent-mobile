import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/client.dart';
import 'certificates_constants.dart';

class CertificateLink {
  const CertificateLink({
    required this.id,
    required this.name,
    required this.url,
    required this.version,
    required this.suggested,
    required this.sentCount,
    this.updatedAt,
    this.issuer,
    this.issuedDate,
    this.expiryDate,
  });

  final String id;
  final String name;
  final String url;
  final int version;
  final bool suggested;
  final int sentCount;
  final DateTime? updatedAt;
  final String? issuer;
  final String? issuedDate;
  final String? expiryDate;

  CertificateLink copyWith({bool? suggested}) => CertificateLink(
    id: id,
    name: name,
    url: url,
    version: version,
    suggested: suggested ?? this.suggested,
    sentCount: sentCount,
    issuer: issuer,
    issuedDate: issuedDate,
    expiryDate: expiryDate,
  );

  /// Host without "www.", shown instead of the full link.
  String get domain {
    final host = Uri.tryParse(url)?.host ?? '';
    return host.startsWith('www.')
        ? host.substring(4)
        : (host.isEmpty ? url : host);
  }

  bool get isHttps => url.startsWith('https://');

  /// Expiry dates are YYYY-MM-DD, so comparing the strings compares the dates.
  bool isExpired(DateTime now) =>
      expiryDate != null &&
      expiryDate!.compareTo(CertificateConstants.day(now.toUtc())) < 0;

  factory CertificateLink.fromJson(Map<String, dynamic> json) =>
      CertificateLink(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        url: json['url'] as String? ?? '',
        version: json['version'] as int? ?? 1,
        suggested: json['suggested'] as bool? ?? false,
        sentCount: json['sentCount'] as int? ?? 0,
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
        issuer: json['issuer'] as String?,
        issuedDate: json['issuedDate'] as String?,
        expiryDate: json['expiryDate'] as String?,
      );
}

/// Search and filter criteria of the certificate list (UC-S4-CERT-06).
class CertificatesQuery {
  const CertificatesQuery({this.search = '', this.suggested, this.validity});

  final String search;
  final bool? suggested;
  final String? validity;

  bool get isFiltered =>
      search.isNotEmpty || suggested != null || validity != null;

  CertificatesQuery copyWith({
    String? search,
    bool? suggested,
    bool clearSuggested = false,
    String? validity,
    bool clearValidity = false,
  }) => CertificatesQuery(
    search: search ?? this.search,
    suggested: clearSuggested ? null : suggested ?? this.suggested,
    validity: clearValidity ? null : validity ?? this.validity,
  );

  /// The API rejects unknown parameters, so only set criteria are sent.
  Map<String, dynamic> toQueryParameters({required int page}) {
    final keyword = search.trim();
    return {
      'page': page,
      'limit': CertificateConstants.pageSize,
      if (keyword.isNotEmpty) 'search': keyword,
      if (suggested != null) 'suggested': suggested.toString(),
      if (validity != null) 'validity': validity,
    };
  }
}

class CertificatesQueryNotifier extends Notifier<CertificatesQuery> {
  @override
  CertificatesQuery build() => const CertificatesQuery();

  // Replacing the query makes [certificatesProvider] reload from page 1.
  void update(CertificatesQuery query) => state = query;

  void clear() => state = const CertificatesQuery();
}

final certificatesQueryProvider =
    NotifierProvider.autoDispose<CertificatesQueryNotifier, CertificatesQuery>(
      CertificatesQueryNotifier.new,
    );

class CertificatesListState {
  const CertificatesListState({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.suggestedTotal,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<CertificateLink> items;
  final int page;
  final int totalPages;
  final int total;
  final int suggestedTotal;
  final bool loadingMore;
  final bool loadMoreFailed;

  bool get hasMore => page < totalPages;

  CertificatesListState copyWith({
    List<CertificateLink>? items,
    int? page,
    int? totalPages,
    int? suggestedTotal,
    bool? loadingMore,
    bool? loadMoreFailed,
  }) => CertificatesListState(
    items: items ?? this.items,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    total: total,
    suggestedTotal: suggestedTotal ?? this.suggestedTotal,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

class CertificatesNotifier extends AsyncNotifier<CertificatesListState> {
  @override
  Future<CertificatesListState> build() async {
    final first = await _fetch(ref.watch(certificatesQueryProvider), 1);
    return CertificatesListState(
      items: first.items,
      page: first.page,
      totalPages: first.totalPages,
      total: first.total,
      suggestedTotal: first.suggestedTotal,
    );
  }

  Future<
    ({
      List<CertificateLink> items,
      int page,
      int totalPages,
      int total,
      int suggestedTotal,
    })
  >
  _fetch(CertificatesQuery query, int page) async {
    final response = await ref
        .read(apiClientProvider)
        .get<Map<String, dynamic>>(
          CertificateConstants.listPath,
          queryParameters: query.toQueryParameters(page: page),
        );
    final data = response.data ?? const {};
    return (
      items: ((data['items'] as List<dynamic>?) ?? const [])
          .map((e) => CertificateLink.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: data['page'] as int? ?? page,
      totalPages: data['totalPages'] as int? ?? 0,
      total: data['total'] as int? ?? 0,
      suggestedTotal: data['suggestedTotal'] as int? ?? 0,
    );
  }

  /// Flips "Suggest when I apply" at once, then PATCHes it with the version shown.
  /// Returns the saved link; on failure the switch goes back and the error is rethrown.
  Future<CertificateLink> setSuggested(CertificateLink item, bool value) async {
    final delta = value == item.suggested ? 0 : (value ? 1 : -1);
    _replace(item.copyWith(suggested: value), delta);
    try {
      final response = await ref
          .read(apiClientProvider)
          .patch<Map<String, dynamic>>(
            CertificateConstants.itemPath(item.id),
            data: {'expectedVersion': item.version, 'suggested': value},
          );
      final saved = CertificateLink.fromJson(response.data ?? const {});
      _replace(saved, 0);
      return saved;
    } catch (_) {
      _replace(item, -delta);
      rethrow;
    }
  }

  void _replace(CertificateLink link, int suggestedDelta) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        items: [for (final e in current.items) e.id == link.id ? link : e],
        suggestedTotal: current.suggestedTotal + suggestedDelta,
      ),
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
      final next = await _fetch(
        ref.read(certificatesQueryProvider),
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

final certificatesProvider =
    AsyncNotifierProvider.autoDispose<
      CertificatesNotifier,
      CertificatesListState
    >(CertificatesNotifier.new);

/// What the add / edit form collects. Empty optional fields are null.
class CertificateDraft {
  const CertificateDraft({
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
}

/// Writes on the Candidate's certificates. Every success refreshes the list.
class CertificateActions {
  CertificateActions(this._ref);

  final Ref _ref;

  /// UC-S4-CERT-01. Reusing [idempotencyKey] for a retry returns the committed link
  /// instead of creating a second one.
  Future<void> create({
    required String idempotencyKey,
    required CertificateDraft draft,
  }) async {
    await _ref
        .read(apiClientProvider)
        .post<Map<String, dynamic>>(
          CertificateConstants.listPath,
          data: {
            'name': draft.name,
            'url': draft.url,
            if (draft.issuer != null) 'issuer': draft.issuer,
            if (draft.issuedDate != null) 'issuedDate': draft.issuedDate,
            if (draft.expiryDate != null) 'expiryDate': draft.expiryDate,
          },
          options: Options(
            headers: {CertificateConstants.idempotencyHeader: idempotencyKey},
          ),
        );
    _ref.invalidate(certificatesProvider);
  }

  /// UC-S4-CERT-02. Sends only what changed, with the version the form was opened on;
  /// a cleared optional field goes as null. Nothing is sent when nothing changed.
  Future<void> update({
    required CertificateLink current,
    required CertificateDraft draft,
    bool? suggested,
  }) async {
    final changes = <String, dynamic>{
      if (draft.name != current.name) 'name': draft.name,
      if (draft.url != current.url) 'url': draft.url,
      if (draft.issuer != current.issuer) 'issuer': draft.issuer,
      if (draft.issuedDate != current.issuedDate)
        'issuedDate': draft.issuedDate,
      if (draft.expiryDate != current.expiryDate)
        'expiryDate': draft.expiryDate,
      if (suggested != null && suggested != current.suggested)
        'suggested': suggested,
    };
    if (changes.isEmpty) return;
    await _ref
        .read(apiClientProvider)
        .patch<Map<String, dynamic>>(
          CertificateConstants.itemPath(current.id),
          data: {'expectedVersion': current.version, ...changes},
        );
    _ref.invalidate(certificatesProvider);
  }

  /// UC-S4-CERT-03. Applications already sent keep their own copy.
  Future<void> delete(CertificateLink current) async {
    await _ref
        .read(apiClientProvider)
        .delete<void>(
          CertificateConstants.itemPath(current.id),
          queryParameters: {'expectedVersion': current.version},
        );
    _ref.invalidate(certificatesProvider);
  }
}

final certificateActionsProvider = Provider<CertificateActions>(
  CertificateActions.new,
);
