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
import 'widgets/job_card.dart';
import 'widgets/job_card_skeleton.dart';

/// UC-BJOB-01: the open jobs of every company, newest first.
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

  Widget _list(BuildContext context, WidgetRef ref, List<JobPosting> jobs) {
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
        itemCount: jobs.length + 2,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              JobFormat.countText('jobs.count', jobs.length),
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.foreground,
              ),
            );
          }
          if (index == jobs.length + 1) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  JobFormat.countText('jobs.end', jobs.length),
                  style: mutedStyle,
                ),
              ),
            );
          }
          return JobCard(job: jobs[index - 1]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(publicJobsProvider);

    return ScreenScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _heading(context),
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
              data: (data) => data.isEmpty
                  ? AppEmptyState(
                      icon: const Icon(LucideIcons.briefcase),
                      title: tr('jobs.empty.title'),
                      description: tr('jobs.empty.description'),
                    )
                  : _list(context, ref, data),
            ),
          ),
        ],
      ),
    );
  }
}
