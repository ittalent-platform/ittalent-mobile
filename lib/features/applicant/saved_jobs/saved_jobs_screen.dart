import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/common/app_empty_state.dart';
import '../../../components/common/app_error_state.dart';
import '../../../components/common/app_toast.dart';
import '../../../components/layout/screen_scaffold.dart';
import '../../../components/ui/app_card.dart';
import '../../../components/ui/app_skeleton.dart';
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'saved_jobs_constants.dart';
import 'saved_jobs_models.dart';
import 'saved_jobs_providers.dart';
import 'widgets/remove_unavailable_dialog.dart';
import 'widgets/saved_job_card.dart';
import 'widgets/unavailable_job_card.dart';

class SavedJobsScreen extends ConsumerStatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  ConsumerState<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends ConsumerState<SavedJobsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  final Set<String> _removingIds = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final trimmed = value.trim();
      final limited = trimmed.length > SavedJobsConstants.maxSearchLength
          ? trimmed.substring(0, SavedJobsConstants.maxSearchLength)
          : trimmed;
      ref
          .read(savedJobsQueryProvider.notifier)
          .setSearch(limited.isEmpty ? null : limited);
    });
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    _debounce?.cancel();
    ref.read(savedJobsQueryProvider.notifier).setSearch(null);
    setState(() {});
  }

  Future<void> _handleRemoveAvailable(SavedJobItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _removingIds.add(item.id));

    try {
      await ref
          .read(savedJobsListProvider.notifier)
          .removeJob(id: item.id, jobId: item.jobId);

      if (!mounted) return;
      showAppToast(
        messenger,
        tr('savedJobs.toast.removedTitle'),
        action: SnackBarAction(
          label: tr('savedJobs.toast.undo'),
          textColor: Colors.white,
          onPressed: () {
            ref.read(savedJobsListProvider.notifier).undoRemove(item.jobId);
          },
        ),
      );
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        messenger,
        tr('savedJobs.toast.errorRemoveFallback'),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _removingIds.remove(item.id));
      }
    }
  }

  Future<void> _handleRequestRemoveUnavailable(SavedJobItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await RemoveUnavailableDialog.show(
      context,
      onConfirm: () async {
        setState(() => _removingIds.add(item.id));
        try {
          await ref
              .read(savedJobsListProvider.notifier)
              .removeJob(id: item.id, jobId: item.jobId);

          if (!mounted) return;
          showAppToast(messenger, tr('savedJobs.toast.removedTitle'));
        } catch (_) {
          if (!mounted) return;
          showAppToast(
            messenger,
            tr('savedJobs.toast.errorRemoveFallback'),
            error: true,
          );
        } finally {
          if (mounted) {
            setState(() => _removingIds.remove(item.id));
          }
        }
      },
    );
    if (confirmed != true) return;
  }

  Widget _buildTabs(BuildContext context, SavedJobsCounts counts) {
    final colors = context.colors;
    final activeTab = ref.watch(savedJobsQueryProvider).status;

    final tabs = [
      (
        id: SavedJobsConstants.tabAll,
        label: tr('savedJobs.tabs.all'),
        count: counts.all,
      ),
      (
        id: SavedJobsConstants.tabAvailable,
        label: tr('savedJobs.tabs.available'),
        count: counts.available,
      ),
      (
        id: SavedJobsConstants.tabUnavailable,
        label: tr('savedJobs.tabs.unavailable'),
        count: counts.unavailable,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.muted.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final tab in tabs) ...[
              Builder(
                builder: (context) {
                  final isActive = activeTab == tab.id;
                  return InkWell(
                    key: Key('saved_jobs_tab_${tab.id}'),
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      ref.read(savedJobsQueryProvider.notifier).setTab(tab.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? colors.card : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isActive ? colors.border : Colors.transparent,
                          width: 1,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tab.label,
                            style: AppTypography.body(
                              fontSize: 13,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isActive
                                  ? colors.foreground
                                  : colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? colors.muted.withValues(alpha: 0.4)
                                  : colors.muted.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${tab.count}',
                              style: AppTypography.body(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? colors.foreground
                                    : colors.mutedForeground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (tab != tabs.last) const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(
    BuildContext context, {
    required int page,
    required int totalPages,
    required int total,
  }) {
    final colors = context.colors;
    final start = (page - 1) * SavedJobsConstants.pageSize + 1;
    final end = (page * SavedJobsConstants.pageSize).clamp(1, total);

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: Column(
        children: [
          Divider(color: colors.border.withValues(alpha: 0.6), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr(
                  'savedJobs.pagination.showing',
                  namedArgs: {
                    'start': '$start',
                    'end': '$end',
                    'total': '$total',
                  },
                ),
                style: AppTypography.body(
                  fontSize: 13,
                  color: colors.mutedForeground,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft, size: 18),
                    onPressed: page > 1
                        ? () {
                            ref
                                .read(savedJobsQueryProvider.notifier)
                                .setPage(page - 1);
                          }
                        : null,
                  ),
                  Text(
                    '$page / $totalPages',
                    style: AppTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.chevronRight, size: 18),
                    onPressed: page < totalPages
                        ? () {
                            ref
                                .read(savedJobsQueryProvider.notifier)
                                .setPage(page + 1);
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final query = ref.watch(savedJobsQueryProvider);
    final asyncList = ref.watch(savedJobsListProvider);
    final asyncCounts = ref.watch(savedJobsCountsProvider);
    final counts = asyncCounts.asData?.value ?? const SavedJobsCounts();

    return ScreenScaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: tr('common.back'),
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.profile),
        ),
        title: Text(
          tr('savedJobs.title'),
          style: AppTypography.display(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.foreground,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(savedJobsCountsProvider);
          ref.invalidate(savedJobsListProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search field
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.8),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.search,
                          size: 16,
                          color: colors.mutedForeground,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: AppTypography.body(
                              fontSize: 13.5,
                              color: colors.foreground,
                            ),
                            decoration: InputDecoration(
                              hintText: tr(
                                'savedJobs.toolbar.searchPlaceholder',
                              ),
                              hintStyle: AppTypography.body(
                                fontSize: 13.5,
                                color: colors.mutedForeground,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty) ...[
                          Text(
                            '${_searchController.text.length}/${SavedJobsConstants.maxSearchLength}',
                            style: AppTypography.body(
                              fontSize: 11,
                              color: colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: _clearSearch,
                            child: Icon(
                              LucideIcons.x,
                              size: 16,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Segmented Tabs
                  _buildTabs(context, counts),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Content List
            asyncList.when(
              loading: () => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: List.generate(
                      3,
                      (index) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSkeleton(width: 180, height: 18),
                              SizedBox(height: 8),
                              AppSkeleton(width: 120, height: 14),
                              SizedBox(height: 16),
                              AppSkeleton(width: double.infinity, height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              error: (err, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: AppErrorState(
                  title: tr('savedJobs.error.title'),
                  message: tr('savedJobs.error.description'),
                  retryText: tr('savedJobs.error.retry'),
                  onRetry: () => ref.invalidate(savedJobsListProvider),
                ),
              ),
              data: (response) {
                final items = response.items;

                if (items.isEmpty) {
                  if (query.q != null && query.q!.isNotEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        icon: const Icon(LucideIcons.search),
                        title: tr(
                          'savedJobs.empty.searchNoMatchTitle',
                          namedArgs: {'query': query.q!},
                        ),
                        description: tr(
                          'savedJobs.empty.searchNoMatchDescription',
                        ),
                        actionText: tr('savedJobs.toolbar.clearSearch'),
                        onAction: _clearSearch,
                      ),
                    );
                  }

                  if (query.status == SavedJobsConstants.tabUnavailable &&
                      counts.unavailable == 0) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        icon: const Icon(LucideIcons.check),
                        title: tr('savedJobs.allAvailable.title'),
                        actionText: tr('savedJobs.allAvailable.showAll'),
                        onAction: () {
                          ref
                              .read(savedJobsQueryProvider.notifier)
                              .setTab(SavedJobsConstants.tabAll);
                        },
                      ),
                    );
                  }

                  if (counts.all == 0) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        icon: const Icon(LucideIcons.bookmark),
                        title: tr('savedJobs.empty.title'),
                        description: tr('savedJobs.empty.description'),
                        actionText: tr('savedJobs.empty.browseJobs'),
                        onAction: () => context.go(AppRoutes.jobs),
                      ),
                    );
                  }

                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: const Icon(LucideIcons.search),
                      title: tr('savedJobs.empty.title'),
                      actionText: tr('savedJobs.allAvailable.showAll'),
                      onAction: () {
                        ref
                            .read(savedJobsQueryProvider.notifier)
                            .setTab(SavedJobsConstants.tabAll);
                      },
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = items[index];
                    final isRemoving = _removingIds.contains(item.id);

                    final cardWidget = item.isAvailable
                        ? SavedJobCard(
                            item: item,
                            isRemoving: isRemoving,
                            onRemove: _handleRemoveAvailable,
                            onTap: () =>
                                context.push(AppRoutes.jobDetail(item.jobId)),
                          )
                        : UnavailableJobCard(
                            item: item,
                            isRemoving: isRemoving,
                            onRequestRemove: _handleRequestRemoveUnavailable,
                          );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: cardWidget,
                    );
                  }, childCount: items.length),
                );
              },
            ),

            // Pagination footer
            if (!asyncList.hasError &&
                asyncList.asData != null &&
                asyncList.asData!.value.totalPages > 1)
              SliverToBoxAdapter(
                child: _buildPagination(
                  context,
                  page: asyncList.asData!.value.page,
                  totalPages: asyncList.asData!.value.totalPages,
                  total: asyncList.asData!.value.total,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
