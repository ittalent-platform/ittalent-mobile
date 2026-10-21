import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/common/app_empty_state.dart';
import '../../../components/common/app_error_state.dart';
import '../../../components/layout/screen_scaffold.dart';
import '../../../components/ui/app_badge.dart';
import '../../../components/ui/app_card.dart';
import '../../../components/ui/app_skeleton.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'applications_constants.dart';
import 'applications_providers.dart';

class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final asyncApplications = ref.watch(myApplicationsProvider);

    return ScreenScaffold(
      appBar: AppBar(
        title: Text(tr('accountNav.myApplications')),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () => ref.invalidate(myApplicationsProvider),
          ),
        ],
      ),
      body: asyncApplications.when(
        loading: () => ListView.separated(
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
        ),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(myApplicationsProvider),
        ),
        data: (applications) {
          if (applications.isEmpty) {
            return const AppEmptyState(
              icon: Icon(LucideIcons.inbox),
              title: 'No applications yet',
              description:
                  'Apply to open positions to track your progress here.',
            );
          }

          return RefreshIndicator(
            color: colors.primary,
            onRefresh: () async => ref.refresh(myApplicationsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: applications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = applications[index];
                final tone = ApplicationConstants.badgeToneForStatus(
                  item.status,
                );
                final statusLabel = ApplicationConstants.labelForStatus(
                  item.status,
                );

                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.jobTitle,
                              style: AppTypography.display(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.foreground,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppBadge(label: statusLabel, tone: tone),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.companyName,
                        style: AppTypography.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (item.location != null) ...[
                            Icon(
                              LucideIcons.mapPin,
                              size: 14,
                              color: colors.mutedForeground,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.location!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body(
                                  fontSize: 12,
                                  color: colors.mutedForeground,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ] else ...[
                            const Spacer(),
                          ],
                          Icon(
                            LucideIcons.calendar,
                            size: 14,
                            color: colors.mutedForeground,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.appliedAt,
                            style: AppTypography.body(
                              fontSize: 12,
                              color: colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.id,
                            style: AppTypography.mono(
                              fontSize: 12,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
