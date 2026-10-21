import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../api/api_error.dart';
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

/// UC-S3-MYAPP-03: append-only status history, public actor role only.
class ApplicationHistoryScreen extends ConsumerWidget {
  const ApplicationHistoryScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final history = ref.watch(applicationHistoryProvider(applicationId));
    return ScreenScaffold(
      appBar: AppBar(title: Text(tr('applications.history.title'))),
      body: history.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: AppCard(child: AppSkeleton(width: 200, height: 18)),
        ),
        error: (error, _) => error is ApiError && error.isNotFound
            ? AppEmptyState(
                icon: const Icon(LucideIcons.fileX),
                title: tr('applications.notFound'),
                description: tr('applications.notFoundDescription'),
              )
            : AppErrorState(
                title: tr('applications.historyError'),
                message: error is ApiError
                    ? error.message
                    : tr('applications.loadErrorHint'),
                retryText: tr('applications.retry'),
                onRetry: () =>
                    ref.invalidate(applicationHistoryProvider(applicationId)),
              ),
        data: (entries) {
          if (entries.isEmpty) {
            return AppEmptyState(
              icon: const Icon(LucideIcons.history),
              title: tr('applications.noHistory'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: entries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final when = entry.occurredAt == null
                  ? ''
                  : ApplicationConstants.day(entry.occurredAt!);
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBadge(
                      label: tr(ApplicationConstants.statusKey(entry.status)),
                      tone: ApplicationConstants.badgeToneForStatus(
                        entry.status,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        tr('applications.actor.${entry.actorRole}'),
                        if (entry.reviewStage != null)
                          tr('applications.stage.${entry.reviewStage}'),
                        when,
                      ].where((part) => part.isNotEmpty).join(' · '),
                      style: AppTypography.body(
                        fontSize: 13,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
