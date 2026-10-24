import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/common/app_empty_state.dart';
import '../../../components/layout/screen_scaffold.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'jobs_format.dart';
import 'jobs_models.dart';
import 'jobs_providers.dart';
import 'jobs_query.dart';
import 'widgets/job_card.dart';
import 'widgets/job_card_skeleton.dart';
import 'widgets/job_chip.dart';
import 'widgets/job_search_field.dart';
import 'widgets/job_search_page.dart';
import 'widgets/job_sort_menu.dart';

/// UC-BJOB-01/02: the open jobs of every company, searched by keyword and
/// sorted (newest first to begin with).
class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  static const double headingSize = 30;
  static const double underlineHeight = 3;
  static const int skeletonCount = 4;

  Widget _heading(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.primary, width: underlineHeight),
        ),
      ),
      child: Text(
        tr('nav.jobs'),
        style: AppTypography.display(
          fontSize: headingSize,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
      ),
    );
  }

  Widget _skeleton() => ListView.separated(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(vertical: 16),
    itemCount: skeletonCount,
    separatorBuilder: (context, index) => const SizedBox(height: 12),
    itemBuilder: (context, index) => const JobCardSkeleton(),
  );

  Future<void> _openSearch(BuildContext context, WidgetRef ref) async {
    final query = ref.read(jobsQueryProvider);
    final keyword = await JobSearchPage.open(context, initial: query.search);
    if (keyword == null) return;
    ref
        .read(jobsQueryProvider.notifier)
        .update(ref.read(jobsQueryProvider).copyWith(search: keyword));
  }

  /// The keyword being searched, removed by tapping it.
  Widget _appliedFilters(WidgetRef ref, JobsQuery query) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Align(
      alignment: Alignment.centerLeft,
      child: JobChip(
        label: '“${query.search.trim()}”',
        showClose: true,
        selected: true,
        onTap: () => ref.read(jobsQueryProvider.notifier).clear(),
      ),
    ),
  );

  Widget _summary(
    BuildContext context,
    WidgetRef ref,
    JobsQuery query,
    int count,
  ) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              JobFormat.countText(
                query.isFiltered ? 'jobs.matches' : 'jobs.count',
                count,
              ),
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.foreground,
              ),
            ),
          ),
          JobSortMenu(
            sort: query.sort,
            onSelected: (sort) => ref
                .read(jobsQueryProvider.notifier)
                .update(query.copyWith(sort: sort)),
          ),
        ],
      ),
    );
  }

  /// The last line of the list: how many jobs were seen, or, when the page cap
  /// left some out, that only the newest ones were read (and out of how many).
  String _endText(PublicJobs data, int shown) => data.isPartial
      ? tr(
          'jobs.endPartial',
          namedArgs: {'count': '${data.jobs.length}', 'total': '${data.total}'},
        )
      : JobFormat.countText('jobs.end', shown);

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    List<JobPosting> jobs,
    PublicJobs data,
  ) {
    final colors = context.colors;
    final mutedStyle = AppTypography.body(
      fontSize: 13,
      color: colors.mutedForeground,
    );
    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () => ref.refresh(publicJobsProvider.future),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: jobs.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == jobs.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  _endText(data, jobs.length),
                  textAlign: TextAlign.center,
                  style: mutedStyle,
                ),
              ),
            );
          }
          return JobCard(job: jobs[index]);
        },
      ),
    );
  }

  /// The jobs matching [query]: a count with the sort menu above the list,
  /// or a message when none match.
  Widget _results(
    BuildContext context,
    WidgetRef ref,
    JobsQuery query,
    PublicJobs data,
  ) {
    final jobs = query.apply(data.jobs);
    if (jobs.isEmpty) {
      return AppEmptyState(
        icon: const Icon(LucideIcons.searchX),
        title: tr('jobs.noMatch.title'),
        description: tr('jobs.noMatch.description'),
        actionText: tr('actions.clear'),
        onAction: () => ref.read(jobsQueryProvider.notifier).clear(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summary(context, ref, query, jobs.length),
        Expanded(child: _list(context, ref, jobs, data)),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(publicJobsProvider);
    final query = ref.watch(jobsQueryProvider);

    return ScreenScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _heading(context),
          const SizedBox(height: 16),
          JobSearchField(onTap: () => _openSearch(context, ref)),
          if (query.isFiltered) _appliedFilters(ref, query),
          Expanded(
            child: jobs.when(
              skipLoadingOnReload: false,
              loading: _skeleton,
              error: (_, _) => AppEmptyState(
                icon: const Icon(LucideIcons.triangleAlert),
                title: tr('jobs.loadError.title'),
                description: tr('jobs.loadError.description'),
                actionText: tr('errorState.retry'),
                onAction: () => ref.invalidate(publicJobsProvider),
              ),
              data: (data) => data.jobs.isEmpty
                  ? AppEmptyState(
                      icon: const Icon(LucideIcons.briefcase),
                      title: tr('jobs.empty.title'),
                      description: tr('jobs.empty.description'),
                    )
                  : _results(context, ref, query, data),
            ),
          ),
        ],
      ),
    );
  }
}
