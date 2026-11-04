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
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'job_filters_screen.dart';
import 'job_search_screen.dart';
import 'jobs_format.dart';
import 'jobs_models.dart';
import 'jobs_providers.dart';
import 'jobs_query.dart';
import 'widgets/job_card.dart';
import 'widgets/job_card_skeleton.dart';
import 'widgets/job_filter_bar.dart';
import 'widgets/job_search_field.dart';
import 'widgets/job_sort_menu.dart';

/// UC-BJOB-01 and UC-BJOB-04: the open jobs of every company, newest first,
/// with a search by keyword, filters and a sort order.
class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  static const int skeletonCount = 4;

  Widget _skeleton() => ListView.separated(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(vertical: 16),
    itemCount: skeletonCount,
    separatorBuilder: (context, index) => const SizedBox(height: 12),
    itemBuilder: (context, index) => const JobCardSkeleton(),
  );

  Future<void> _openSearch(BuildContext context, WidgetRef ref) async {
    final keyword = await JobSearchScreen.open(
      context,
      initial: ref.read(jobsQueryProvider).search,
    );
    if (keyword == null || !context.mounted) return;
    final notifier = ref.read(jobsQueryProvider.notifier);
    notifier.update(ref.read(jobsQueryProvider).copyWith(search: keyword));
  }

  Future<void> _openFilters(BuildContext context, WidgetRef ref) async {
    final result = await JobFiltersScreen.open(
      context,
      ref.read(jobsQueryProvider),
    );
    if (result == null || !context.mounted) return;
    ref.read(jobsQueryProvider.notifier).update(result);
  }

  // The message sits in a scrollable page, so a pull down refreshes it like the list.
  Widget _message(BuildContext context, WidgetRef ref, Widget child) {
    return RefreshIndicator(
      color: context.colors.primary,
      onRefresh: () => ref.refresh(publicJobsProvider.future),
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

  Widget _header(
    BuildContext context,
    WidgetRef ref,
    int count,
    JobsQuery query,
  ) {
    final colors = context.colors;
    final countText = JobFormat.countText('jobs.count', count);
    final style = AppTypography.body(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: colors.foreground,
    );
    return Row(
      children: [
        Expanded(
          child: query.isFiltered
              ? Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: countText, style: style),
                      TextSpan(
                        text: ' ${tr('jobs.matchSuffix')}',
                        style: AppTypography.body(
                          fontSize: 14,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                )
              : Text(countText, style: style),
        ),
        JobSortMenu(
          sort: query.sort,
          onSelected: (sort) => ref
              .read(jobsQueryProvider.notifier)
              .update(ref.read(jobsQueryProvider).copyWith(sort: sort)),
        ),
      ],
    );
  }

  Widget _footer(
    BuildContext context,
    WidgetRef ref,
    int shown,
    JobsQuery query,
  ) {
    final colors = context.colors;
    final text = JobFormat.countText('jobs.end', shown);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.body(
              fontSize: 13,
              color: colors.mutedForeground,
            ),
          ),
          if (query.isFiltered) ...[
            const SizedBox(height: 12),
            AppButton(
              text: tr('actions.clear'),
              variant: AppButtonVariant.outline,
              isFullWidth: true,
              onPressed: ref.read(jobsQueryProvider.notifier).clear,
            ),
          ],
        ],
      ),
    );
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    PublicJobs data,
    List<JobPosting> jobs,
    JobsQuery query,
  ) {
    return RefreshIndicator(
      color: context.colors.primary,
      onRefresh: () => ref.refresh(publicJobsProvider.future),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: jobs.length + 2,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) return _header(context, ref, jobs.length, query);
          if (index == jobs.length + 1) {
            return _footer(context, ref, jobs.length, query);
          }
          final job = jobs[index - 1];
          return JobCard(
            job: job,
            onTap: () => context.push(AppRoutes.jobDetail(job.id)),
          );
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<PublicJobs> jobs,
    JobsQuery query,
  ) {
    return jobs.when(
      skipLoadingOnReload: false,
      loading: _skeleton,
      error: (_, _) => AppErrorState(
        title: tr('jobs.loadError.title'),
        message: tr('jobs.loadError.description'),
        retryText: tr('errorState.retry'),
        onRetry: () => ref.invalidate(publicJobsProvider),
      ),
      data: (data) {
        if (data.jobs.isEmpty) {
          return _message(
            context,
            ref,
            AppEmptyState(
              icon: const Icon(LucideIcons.briefcase),
              title: tr('jobs.empty.title'),
              description: tr('jobs.empty.description'),
            ),
          );
        }
        final matching = query.apply(data.jobs);
        if (matching.isEmpty) {
          return _message(
            context,
            ref,
            AppEmptyState(
              icon: const Icon(LucideIcons.searchX),
              title: tr('jobs.noMatches.title'),
              description: tr('jobs.noMatches.description'),
              actionText: tr('actions.clear'),
              onAction: ref.read(jobsQueryProvider.notifier).clear,
            ),
          );
        }
        return _list(context, ref, data, matching, query);
      },
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
          const ExploreHeader(selected: ExploreTab.jobs),
          JobSearchField(onTap: () => _openSearch(context, ref)),
          const SizedBox(height: 12),
          JobFilterBar(
            query: query,
            onOpenFilters: () => _openFilters(context, ref),
            onChanged: ref.read(jobsQueryProvider.notifier).update,
          ),
          const SizedBox(height: 8),
          Expanded(child: _body(context, ref, jobs, query)),
        ],
      ),
    );
  }
}
