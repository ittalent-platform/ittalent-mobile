import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/client.dart';
import '../../../auth/auth_notifier.dart';
import 'saved_jobs_constants.dart';
import 'saved_jobs_models.dart';

/// Provider for tab counts: all, available, unavailable.
final savedJobsCountsProvider = FutureProvider.autoDispose<SavedJobsCounts>((
  ref,
) async {
  if (!ref.watch(authNotifierProvider).isAuthenticated) {
    return const SavedJobsCounts();
  }
  final client = ref.watch(apiClientProvider);

  Future<int> fetchTotal(String status) async {
    try {
      final res = await client.get<Map<String, dynamic>>(
        SavedJobsConstants.wishlistPath,
        queryParameters: {'status': status, 'limit': 1},
      );
      return (res.data?['total'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  final results = await Future.wait([
    fetchTotal(SavedJobsConstants.tabAll),
    fetchTotal(SavedJobsConstants.tabAvailable),
    fetchTotal(SavedJobsConstants.tabUnavailable),
  ]);

  return SavedJobsCounts(
    all: results[0],
    available: results[1],
    unavailable: results[2],
  );
});

class SavedJobsQueryNotifier extends Notifier<SavedJobsQuery> {
  @override
  SavedJobsQuery build() => const SavedJobsQuery();

  void setTab(String tab) {
    state = state.copyWith(status: tab, page: 1);
  }

  void setSearch(String? q) {
    final trimmed = q?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      state = state.copyWith(clearQuery: true, page: 1);
    } else {
      state = state.copyWith(q: trimmed, page: 1);
    }
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
  }
}

final savedJobsQueryProvider =
    NotifierProvider.autoDispose<SavedJobsQueryNotifier, SavedJobsQuery>(
      SavedJobsQueryNotifier.new,
    );

class SavedJobsListNotifier extends AsyncNotifier<SavedJobsResponse> {
  @override
  Future<SavedJobsResponse> build() async {
    final isAuthenticated = ref.watch(authNotifierProvider).isAuthenticated;
    if (!isAuthenticated) {
      return const SavedJobsResponse(
        items: [],
        total: 0,
        page: 1,
        totalPages: 1,
      );
    }
    final query = ref.watch(savedJobsQueryProvider);
    final client = ref.watch(apiClientProvider);

    final res = await client.get<Map<String, dynamic>>(
      SavedJobsConstants.wishlistPath,
      queryParameters: query.toQueryParams(),
    );

    return SavedJobsResponse.fromJson(res.data ?? const {});
  }

  Future<void> removeJob({required String id, required String jobId}) async {
    final client = ref.read(apiClientProvider);
    await client.delete<Map<String, dynamic>>(
      SavedJobsConstants.wishlistJobPath(jobId),
    );
    ref.invalidate(savedJobsCountsProvider);
    ref.invalidateSelf();
  }

  Future<void> undoRemove(String jobId) async {
    final client = ref.read(apiClientProvider);
    await client.post<Map<String, dynamic>>(
      SavedJobsConstants.wishlistPath,
      data: {'jobId': jobId},
    );
    ref.invalidate(savedJobsCountsProvider);
    ref.invalidateSelf();
  }
}

final savedJobsListProvider =
    AsyncNotifierProvider.autoDispose<SavedJobsListNotifier, SavedJobsResponse>(
      SavedJobsListNotifier.new,
    );
