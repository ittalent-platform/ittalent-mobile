import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/common/app_empty_state.dart';
import '../../../components/common/app_error_state.dart';
import '../../../components/common/explore_header.dart';
import '../../../components/layout/screen_scaffold.dart';
import '../../../components/ui/app_button.dart';
import '../../../components/ui/app_filter_pill.dart';
import '../../../components/ui/app_input.dart';
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'companies_constants.dart';
import 'companies_format.dart';
import 'companies_providers.dart';
import 'widgets/companies_filter_sheet.dart';
import 'widgets/company_card.dart';
import 'widgets/company_card_skeleton.dart';

/// UC-BENT-01 and UC-BENT-03: the companies on ITTalent, with a search by
/// name or industry and filters by industry, size and city.
class CompaniesScreen extends ConsumerStatefulWidget {
  const CompaniesScreen({super.key});

  @override
  ConsumerState<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends ConsumerState<CompaniesScreen> {
  static const int skeletonCount = 3;

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
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.extentAfter < CompanyConstants.loadMoreThreshold) {
      ref.read(companiesProvider.notifier).loadMore();
    }
  }

  // A keyword the API would refuse is never sent. Spaces alone are no keyword.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final keyword = value.trim();
    final tooLong = keyword.length > CompanyConstants.searchMaxLength;
    setState(
      () => _searchError = tooLong
          ? tr(
              'companies.errors.keywordTooLong',
              namedArgs: {'max': '${CompanyConstants.searchMaxLength}'},
            )
          : null,
    );
    if (tooLong) return;
    _debounce = Timer(CompanyConstants.searchDebounce, () {
      final notifier = ref.read(companiesQueryProvider.notifier);
      notifier.update(
        ref.read(companiesQueryProvider).copyWith(search: keyword),
      );
    });
  }

  Future<void> _openFilters(Set<CompanyFilterGroup> groups) async {
    final result = await showModalBottomSheet<CompaniesQuery>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CompaniesFilterSheet(
        initial: ref.read(companiesQueryProvider),
        groups: groups,
      ),
    );
    if (result != null && mounted) {
      ref.read(companiesQueryProvider.notifier).update(result);
    }
  }

  void _clearAll() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _searchError = null);
    ref.read(companiesQueryProvider.notifier).clear();
  }

  String _industryLabel(CompaniesQuery query) =>
      switch (query.industries.length) {
        0 => tr('companies.filter.industry'),
        1 => query.industries.single,
        final count => tr(
          'companies.filter.industryCount',
          namedArgs: {'count': '$count'},
        ),
      };

  String _sizeLabel(CompaniesQuery query) => switch (query.sizes.length) {
    0 => tr('companies.filter.size'),
    1 => CompanyFormat.sizeRange(query.sizes.single),
    final count => tr(
      'companies.filter.sizeCount',
      namedArgs: {'count': '$count'},
    ),
  };

  Widget _skeleton() => ListView.separated(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(vertical: 16),
    itemCount: skeletonCount,
    separatorBuilder: (context, index) => const SizedBox(height: 12),
    itemBuilder: (context, index) => const CompanyCardSkeleton(),
  );

  // The message sits in a scrollable page, so a pull down refreshes it like
  // the list.
  Widget _message(Widget child) {
    return RefreshIndicator(
      color: context.colors.primary,
      onRefresh: () => ref.refresh(companiesProvider.future),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _footer(CompaniesListState data) {
    if (data.loadMoreFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(tr('companies.loadMoreFailed')),
            const SizedBox(height: 8),
            AppButton(
              text: tr('errorState.retry'),
              variant: AppButtonVariant.outline,
              onPressed: () =>
                  ref.read(companiesProvider.notifier).loadMore(retry: true),
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

  Widget _count(CompaniesListState data) {
    final colors = context.colors;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: CompanyFormat.countText('companies.count', data.total),
            style: AppTypography.body(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.foreground,
            ),
          ),
          TextSpan(
            text: ' · ${tr('companies.verified')}',
            style: AppTypography.body(
              fontSize: 14,
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(CompaniesListState data) {
    final colors = context.colors;
    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () => ref.refresh(companiesProvider.future),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: data.items.length + 2,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) return _count(data);
          if (index == data.items.length + 1) return _footer(data);
          final company = data.items[index - 1];
          return CompanyCard(
            company: company,
            onTap: () => context.push(AppRoutes.companyDetail(company.id)),
          );
        },
      ),
    );
  }

  Widget _body(AsyncValue<CompaniesListState> companies, CompaniesQuery query) {
    return companies.when(
      skipLoadingOnReload: false,
      loading: _skeleton,
      error: (_, _) => AppErrorState(
        title: tr('companies.loadError.title'),
        message: tr('companies.loadError.description'),
        retryText: tr('errorState.retry'),
        onRetry: () => ref.invalidate(companiesProvider),
      ),
      data: (data) {
        if (data.items.isNotEmpty) return _list(data);
        return _message(
          query.isFiltered
              ? AppEmptyState(
                  icon: const Icon(LucideIcons.searchX),
                  title: tr('companies.noMatches.title'),
                  description: tr('companies.noMatches.description'),
                  actionText: tr('companies.noMatches.clear'),
                  onAction: _clearAll,
                )
              : AppEmptyState(
                  icon: const Icon(LucideIcons.building2),
                  title: tr('companies.empty.title'),
                  description: tr('companies.empty.description'),
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(companiesQueryProvider);
    final companies = ref.watch(companiesProvider);

    return ScreenScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExploreHeader(selected: ExploreTab.companies),
          AppInput(
            controller: _searchController,
            hintText: tr('companies.search'),
            errorText: _searchError,
            prefixIcon: const Icon(LucideIcons.search, size: 18),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FiltersButton(
                  label: tr('companies.filter.title'),
                  onTap: () => _openFilters(CompanyFilterGroup.values.toSet()),
                ),
                const SizedBox(width: 8),
                AppFilterPill(
                  label: _industryLabel(query),
                  active: query.industries.isNotEmpty,
                  onTap: () => _openFilters({CompanyFilterGroup.industry}),
                ),
                const SizedBox(width: 8),
                AppFilterPill(
                  label: _sizeLabel(query),
                  active: query.sizes.isNotEmpty,
                  onTap: () => _openFilters({CompanyFilterGroup.size}),
                ),
                const SizedBox(width: 8),
                AppFilterPill(
                  label: query.city ?? tr('companies.filter.city'),
                  active: query.city != null,
                  onTap: () => _openFilters({CompanyFilterGroup.city}),
                ),
              ],
            ),
          ),
          Expanded(child: _body(companies, query)),
        ],
      ),
    );
  }
}

/// The dark "Filters" pill that opens every filter at once.
class _FiltersButton extends StatelessWidget {
  const _FiltersButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.foreground,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.slidersHorizontal,
                size: 16,
                color: colors.background,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.background,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
