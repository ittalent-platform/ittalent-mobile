import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/common/app_empty_state.dart';
import '../../../../components/common/app_error_state.dart';
import '../../../../components/ui/app_skeleton.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../companies_models.dart';
import '../companies_providers.dart';
import 'company_job_row.dart';

/// The Jobs tab: the open jobs of one company, a few at a time, with "Load
/// more" under them.
class CompanyJobsTab extends ConsumerStatefulWidget {
  const CompanyJobsTab({
    super.key,
    required this.companyId,
    required this.onBrowse,
  });

  final String companyId;

  /// "Browse companies" of the empty state.
  final VoidCallback onBrowse;

  @override
  ConsumerState<CompanyJobsTab> createState() => _CompanyJobsTabState();
}

class _CompanyJobsTabState extends ConsumerState<CompanyJobsTab> {
  static const int skeletonCount = 3;

  /// How many pages the tab shows: "Load more" adds one.
  int _pages = 1;

  ({String companyId, int page}) _key(int page) =>
      (companyId: widget.companyId, page: page);

  Widget _skeleton() => Column(
    children: [
      for (var i = 0; i < skeletonCount; i++)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(width: 220, height: 14),
              SizedBox(height: 8),
              AppSkeleton(width: 150, height: 12),
              SizedBox(height: 8),
              AppSkeleton(width: 180, height: 12),
            ],
          ),
        ),
    ],
  );

  Widget _footer(int shown, int total, {required bool hasMore}) {
    final colors = context.colors;
    final style = AppTypography.body(
      fontSize: 14,
      color: colors.mutedForeground,
    );
    if (!hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${tr('companies.jobs.showing', namedArgs: {'shown': '$shown', 'total': '$total'})} · ',
            style: style,
          ),
          InkWell(
            onTap: () => setState(() => _pages++),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                tr('companies.jobs.loadMore'),
                style: AppTypography.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.fgLink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageFailed() {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Text(
            tr('companies.jobs.loadMoreFailed'),
            style: AppTypography.body(
              fontSize: 14,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => ref.invalidate(companyJobsPageProvider(_key(_pages))),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                tr('errorState.retry'),
                style: AppTypography.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.fgLink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pages = [
      for (var page = 1; page <= _pages; page++)
        ref.watch(companyJobsPageProvider(_key(page))),
    ];
    final first = pages.first;

    if (first.hasError && first.value == null) {
      return AppErrorState(
        title: tr('companies.jobs.loadError.title'),
        message: tr('companies.jobs.loadError.description'),
        retryText: tr('errorState.retry'),
        onRetry: () => ref.invalidate(companyJobsPageProvider(_key(1))),
      );
    }
    if (first.value == null) return _skeleton();

    // A job that moved between pages while they were read is kept once.
    final seen = <String>{};
    final jobs = [
      for (final page in pages)
        for (final job in page.value?.items ?? const <CompanyJob>[])
          if (seen.add(job.id)) job,
    ];
    final last = pages.last;
    final total = first.value!.total;

    if (jobs.isEmpty) {
      return AppEmptyState(
        icon: const Icon(LucideIcons.briefcase),
        title: tr('companies.jobs.empty.title'),
        description: tr('companies.jobs.empty.description'),
        actionText: tr('companies.jobs.empty.browse'),
        onAction: widget.onBrowse,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: colors.card,
          child: Column(
            children: [
              for (var i = 0; i < jobs.length; i++)
                CompanyJobRow(job: jobs[i], last: i == jobs.length - 1),
            ],
          ),
        ),
        if (last.hasError && last.value == null)
          _pageFailed()
        else if (last.value == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          _footer(jobs.length, total, hasMore: last.value!.hasMore),
      ],
    );
  }
}
