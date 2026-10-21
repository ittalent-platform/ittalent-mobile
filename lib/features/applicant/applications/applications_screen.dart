import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../api/api_error.dart';
import '../../../components/common/app_empty_state.dart';
import '../../../components/layout/screen_scaffold.dart';
import '../../../components/ui/app_button.dart';
import '../../../components/ui/app_card.dart';
import '../../../components/ui/app_input.dart';
import '../../../components/ui/app_skeleton.dart';
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
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
    itemCount: 3,
    separatorBuilder: (context, index) => const SizedBox(height: 12),
    itemBuilder: (context, index) => const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 220, height: 14),
          SizedBox(height: 10),
          AppSkeleton(width: 150, height: 12),
        ],
      ),
    ),
  );

  String _statusLabel(ApplicationsQuery query) {
    final statuses = query.statuses;
    final value = statuses.isEmpty
        ? tr('applications.filter.all')
        : statuses.length == 1
        ? tr(ApplicationConstants.statusKey(statuses.single))
        : ApplicationConstants.countText(
            'applications.filter.selected',
            statuses.length,
          );
    return '${tr('applications.filter.status')} $value';
  }

  String _submittedLabel(ApplicationsQuery query) {
    if (query.submittedFrom == null) {
      return '${tr('applications.filter.submitted')} '
          '${tr('applications.range.any')}';
    }
    final preset = ApplicationConstants.presetOf(
      query.submittedFrom,
      DateTime.now(),
    );
    return tr('applications.range.${preset ?? 'custom'}');
  }

  // "N applications across M companies"; companies are only countable once
  // every page is loaded, because the API returns no company total.
  String _subtitle(ApplicationsListState data) {
    final applications = ApplicationConstants.countText(
      'applications.subtitle',
      data.total,
    );
    if (data.hasMore || data.items.isEmpty) return applications;
    final companies = data.items.map((e) => e.companyName).toSet().length;
    return '$applications ${ApplicationConstants.countText('applications.acrossCompanies', companies)}';
  }

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
    final subtitle = asyncApplications.value;

    return ScreenScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            tr('applications.heading'),
            style: AppTypography.display(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
          if (subtitle != null && !asyncApplications.isLoading)
            Text(
              _subtitle(subtitle),
              style: AppTypography.body(
                fontSize: 13,
                color: colors.mutedForeground,
              ),
            ),
          const SizedBox(height: 12),
          AppInput(
            controller: _searchController,
            hintText: tr('applications.search'),
            errorText: _searchError,
            prefixIcon: const Icon(LucideIcons.search, size: 18),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterPill(
                label: _statusLabel(query),
                active: query.statuses.isNotEmpty,
                onTap: _openFilters,
              ),
              _FilterPill(
                label: _submittedLabel(query),
                active: query.submittedFrom != null,
                onTap: _openFilters,
              ),
            ],
          ),
          Expanded(
            child: asyncApplications.when(
              skipLoadingOnReload: false,
              loading: _skeleton,
              error: (error, _) => AppEmptyState(
                icon: const Icon(LucideIcons.triangleAlert),
                title: tr('applications.loadErrorTitle'),
                description: error is ApiError
                    ? error.message
                    : tr('applications.loadErrorHint'),
                actionText: tr('applications.retry'),
                onAction: () => ref.invalidate(myApplicationsProvider),
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
                          icon: const Icon(LucideIcons.fileText),
                          title: tr('applications.noApplications'),
                          description: tr(
                            'applications.noApplicationsDescription',
                          ),
                          actionText: tr('applications.browse'),
                          onAction: () => context.go(AppRoutes.jobs),
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

/// "Status: All" / "Submitted: Any time" dropdown pill; tinted when it filters.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = active ? colors.primary : colors.foreground;
    return Material(
      color: active ? colors.statusPeachBg : colors.card,
      shape: StadiumBorder(
        side: BorderSide(color: active ? colors.primary : colors.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronDown, size: 16, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}
