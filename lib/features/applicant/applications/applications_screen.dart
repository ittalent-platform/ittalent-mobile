import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../api/api_error.dart';
import '../../../components/common/app_empty_state.dart';
import '../../../components/common/app_error_state.dart';
import '../../../components/layout/screen_scaffold.dart';
import '../../../components/ui/app_button.dart';
import '../../../components/ui/app_card.dart';
import '../../../components/ui/app_input.dart';
import '../../../components/ui/app_skeleton.dart';
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import 'applications_constants.dart';
import 'applications_providers.dart';
import 'widgets/application_card.dart';
import 'widgets/applications_filter_sheet.dart';

class ApplicationsScreen extends ConsumerStatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  ConsumerState<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends ConsumerState<ApplicationsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.extentAfter < ApplicationConstants.loadMoreThreshold) {
      ref.read(myApplicationsProvider.notifier).loadMore();
    }
  }

  // E1: spaces alone and over-long keywords are rejected before any request.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final keyword = value.trim();
    String? error;
    if (value.isNotEmpty && keyword.isEmpty) {
      error = tr('applications.errors.keywordBlank');
    } else if (keyword.length > ApplicationConstants.searchMaxLength) {
      error = tr(
        'applications.errors.keywordTooLong',
        namedArgs: {'max': '${ApplicationConstants.searchMaxLength}'},
      );
    }
    setState(() => _searchError = error);
    if (error != null) return;
    _debounce = Timer(ApplicationConstants.searchDebounce, () {
      final notifier = ref.read(applicationsQueryProvider.notifier);
      notifier.update(
        ref.read(applicationsQueryProvider).copyWith(search: keyword),
      );
    });
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<ApplicationsQuery>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          ApplicationsFilterSheet(initial: ref.read(applicationsQueryProvider)),
    );
    if (result != null) {
      ref.read(applicationsQueryProvider.notifier).update(result);
    }
  }

  void _clearAll() {
    _searchController.clear();
    setState(() => _searchError = null);
    ref.read(applicationsQueryProvider.notifier).clear();
  }

  Widget _skeleton() => ListView.separated(
    padding: const EdgeInsets.symmetric(vertical: 16),
    itemCount: 4,
    separatorBuilder: (context, index) => const SizedBox(height: 12),
    itemBuilder: (context, index) => const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 140, height: 18),
          SizedBox(height: 8),
          AppSkeleton(width: 200, height: 14),
          SizedBox(height: 12),
          AppSkeleton(width: 80, height: 24),
        ],
      ),
    ),
  );

  Widget _footer(ApplicationsListState data) {
    if (data.loadMoreFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(tr('applications.loadMoreFailed')),
            const SizedBox(height: 8),
            AppButton(
              text: tr('applications.retry'),
              variant: AppButtonVariant.outline,
              onPressed: ref.read(myApplicationsProvider.notifier).loadMore,
            ),
          ],
        ),
      );
    }
    if (data.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final query = ref.watch(applicationsQueryProvider);
    final asyncApplications = ref.watch(myApplicationsProvider);

    return ScreenScaffold(
      appBar: AppBar(
        title: Text(tr('accountNav.myApplications')),
        actions: [
          IconButton(
            tooltip: tr('applications.filter.title'),
            icon: Icon(
              LucideIcons.listFilter,
              size: 20,
              color:
                  query.statuses.isNotEmpty ||
                      query.reviewStage != null ||
                      query.submittedFrom != null
                  ? colors.primary
                  : null,
            ),
            onPressed: _openFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: AppInput(
              controller: _searchController,
              hintText: tr('applications.search'),
              errorText: _searchError,
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: asyncApplications.when(
              skipLoadingOnReload: false,
              loading: _skeleton,
              error: (error, _) => AppErrorState(
                title: tr('applications.loadErrorTitle'),
                message: error is ApiError
                    ? error.message
                    : tr('applications.loadErrorHint'),
                retryText: tr('applications.retry'),
                onRetry: () => ref.invalidate(myApplicationsProvider),
              ),
              data: (data) {
                if (data.items.isEmpty) {
                  return query.isFiltered
                      ? AppEmptyState(
                          icon: const Icon(LucideIcons.searchX),
                          title: tr('applications.noMatches'),
                          description: tr('applications.noMatchesDescription'),
                          actionText: tr('applications.clearFilters'),
                          onAction: _clearAll,
                        )
                      : AppEmptyState(
                          icon: const Icon(LucideIcons.inbox),
                          title: tr('applications.noApplications'),
                          description: tr(
                            'applications.noApplicationsDescription',
                          ),
                        );
                }
                return RefreshIndicator(
                  color: colors.primary,
                  onRefresh: () => ref.refresh(myApplicationsProvider.future),
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: data.items.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) => index == data.items.length
                        ? _footer(data)
                        : ApplicationCard(
                            item: data.items[index],
                            onTap: () => context.push(
                              AppRoutes.applicationDetail(data.items[index].id),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
