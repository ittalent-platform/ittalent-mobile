import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../api/api_error.dart';
import '../../../components/common/app_empty_state.dart';
import '../../../components/common/app_error_state.dart';
import '../../../components/layout/screen_scaffold.dart';
import '../../../components/ui/app_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'applications_constants.dart';
import 'applications_providers.dart';
import 'widgets/application_skeletons.dart';
import 'widgets/back_link.dart';

/// UC-S3-MYAPP-03: append-only status history, public actor role only.
class ApplicationHistoryScreen extends ConsumerWidget {
  const ApplicationHistoryScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final history = ref.watch(applicationHistoryProvider(applicationId));
    final locale = Localizations.localeOf(context).toString();
    return ScreenScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: BackLink.width,
        leading: BackLink(label: tr('applications.backShort')),
        centerTitle: true,
        title: Text(
          tr('applications.history.title'),
          style: AppTypography.display(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colors.foreground,
          ),
        ),
      ),
      body: history.when(
        loading: () => const ApplicationHistorySkeleton(),
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
          // Newest first, as one timeline card.
          final newestFirst = entries.reversed.toList();
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              AppCard(
                child: Column(
                  children: [
                    for (final entry in newestFirst)
                      _TimelineEntry(entry: entry, locale: locale),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.entry, required this.locale});

  final ApplicationHistoryEntry entry;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final known = ApplicationConstants.statuses.contains(entry.status);
    final title = [
      known ? tr('applications.history.${entry.status}') : entry.status,
      if (entry.reviewStage != null)
        tr('applications.stage.${entry.reviewStage}'),
    ].join(' · ');
    final meta = [
      if (entry.occurredAt != null)
        ApplicationConstants.dateTime(entry.occurredAt!, locale),
      tr('applications.by.${entry.actorRole}'),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: ApplicationConstants.toneColor(entry.status, colors),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
                Text(
                  meta,
                  style: AppTypography.body(
                    fontSize: 12,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
