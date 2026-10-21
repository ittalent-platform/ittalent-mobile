import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../api/api_error.dart';
import '../../../components/common/app_empty_state.dart';
import '../../../components/common/app_error_state.dart';
import '../../../components/layout/screen_scaffold.dart';
import '../../../components/ui/app_badge.dart';
import '../../../components/ui/app_button.dart';
import '../../../components/ui/app_card.dart';
import '../../../components/ui/app_skeleton.dart';
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'applications_constants.dart';
import 'applications_providers.dart';
import 'widgets/withdraw_application_sheet.dart';

/// UC-S3-MYAPP-02: one own application, as it was submitted.
class ApplicationDetailScreen extends ConsumerWidget {
  const ApplicationDetailScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(applicationDetailProvider(applicationId));
    return ScreenScaffold(
      appBar: AppBar(title: Text(tr('applications.detailsTitle'))),
      body: detail.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: 180, height: 20),
                SizedBox(height: 10),
                AppSkeleton(width: 120, height: 14),
              ],
            ),
          ),
        ),
        // E2: a foreign or unknown id looks the same as a missing one.
        error: (error, _) => error is ApiError && error.isNotFound
            ? AppEmptyState(
                icon: const Icon(LucideIcons.fileX),
                title: tr('applications.notFound'),
                description: tr('applications.notFoundDescription'),
              )
            : AppErrorState(
                title: tr('applications.loadErrorTitle'),
                message: error is ApiError
                    ? error.message
                    : tr('applications.loadErrorHint'),
                retryText: tr('applications.retry'),
                onRetry: () =>
                    ref.invalidate(applicationDetailProvider(applicationId)),
              ),
        data: (data) => _Body(detail: data, applicationId: applicationId),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail, required this.applicationId});

  final ApplicationDetail detail;
  final String applicationId;

  Future<void> _withdraw(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final withdrawn = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => WithdrawApplicationSheet(
        applicationId: applicationId,
        expectedVersion: detail.version,
      ),
    );
    if (withdrawn == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          withdrawn
              ? tr(
                  'applications.toast.withdrawnOne',
                  namedArgs: {'id': applicationId},
                )
              : tr('applications.withdrawConflict'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final item = detail.summary;
    TextStyle muted() =>
        AppTypography.body(fontSize: 13, color: colors.mutedForeground);
    Widget heading(String key) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        tr(key),
        style: AppTypography.display(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
      ),
    );
    Widget row(String key, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(tr(key), style: muted())),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.body(fontSize: 13, color: colors.foreground),
            ),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.jobTitle,
                style: AppTypography.display(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(item.companyName, style: muted()),
              const SizedBox(height: 12),
              AppBadge(
                label: tr(ApplicationConstants.statusKey(item.status)),
                tone: ApplicationConstants.badgeToneForStatus(item.status),
              ),
              if (ApplicationConstants.statuses.contains(item.status)) ...[
                const SizedBox(height: 12),
                Text(tr('applications.next.${item.status}'), style: muted()),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading('applications.detailsTitle'),
              row('applications.reference', applicationId),
              if (item.submittedAt != null)
                row(
                  'applications.submitted',
                  ApplicationConstants.day(item.submittedAt!),
                ),
              if (detail.latestStatusAt != null)
                row(
                  'applications.lastUpdate',
                  ApplicationConstants.day(detail.latestStatusAt!),
                ),
              if (item.reviewStage != null)
                row(
                  'applications.stageLabel',
                  tr('applications.stage.${item.reviewStage}'),
                ),
              if (item.location != null)
                row('applications.columns.job', item.location!),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading('applications.documents'),
              if (detail.attachments.isEmpty)
                Text(tr('applications.noDocuments'), style: muted())
              else
                for (final doc in detail.attachments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${tr('applications.attachment.${doc.type}')} · ${doc.fileName}',
                      style: AppTypography.body(
                        fontSize: 13,
                        color: colors.foreground,
                      ),
                    ),
                  ),
            ],
          ),
        ),
        if (detail.certificates.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading('applications.certificates.title'),
                for (final cert in detail.certificates)
                  _CertificateTile(cert: cert),
                Text(tr('applications.certificates.note'), style: muted()),
              ],
            ),
          ),
        ],
        if (detail.message != null && detail.message!.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Text(
              detail.message!,
              style: AppTypography.body(fontSize: 14, color: colors.foreground),
            ),
          ),
        ],
        if (detail.withdrawalReason != null) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Text(
              tr(
                'applications.withdrawnReason',
                namedArgs: {'reason': detail.withdrawalReason!},
              ),
              style: muted(),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (item.canWithdraw) ...[
          AppButton(
            text: tr('applications.withdraw'),
            variant: AppButtonVariant.destructive,
            isFullWidth: true,
            onPressed: () => _withdraw(context),
          ),
          const SizedBox(height: 12),
        ],
        AppButton(
          text: tr('applications.history.title'),
          variant: AppButtonVariant.outline,
          icon: const Icon(LucideIcons.history, size: 18),
          isFullWidth: true,
          onPressed: () =>
              context.push(AppRoutes.applicationHistory(applicationId)),
        ),
      ],
    );
  }
}

class _CertificateTile extends StatelessWidget {
  const _CertificateTile({required this.cert});

  final ApplicationCertificate cert;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dates = [
      if (cert.issuedDate != null)
        tr(
          'applications.certificates.issued',
          namedArgs: {'date': cert.issuedDate!},
        ),
      if (cert.expiryDate != null)
        tr(
          'applications.certificates.expires',
          namedArgs: {'date': cert.expiryDate!},
        ),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => launchUrl(
          Uri.parse(cert.url),
          mode: LaunchMode.externalApplication,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cert.name,
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
            if (cert.issuer != null)
              Text(
                cert.issuer!,
                style: AppTypography.body(
                  fontSize: 12,
                  color: colors.mutedForeground,
                ),
              ),
            if (dates.isNotEmpty)
              Text(
                dates,
                style: AppTypography.body(
                  fontSize: 12,
                  color: colors.mutedForeground,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
