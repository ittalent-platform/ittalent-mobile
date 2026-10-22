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
import '../../../components/ui/app_button.dart';
import '../../../components/ui/app_card.dart';
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'applications_constants.dart';
import 'applications_providers.dart';
import 'widgets/application_skeletons.dart';
import 'widgets/back_link.dart';
import 'widgets/company_avatar.dart';
import 'widgets/offer_notice.dart';

/// UC-S3-MYAPP-02: one own application, as it was submitted.
class ApplicationDetailScreen extends ConsumerWidget {
  const ApplicationDetailScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(applicationDetailProvider(applicationId));
    final loaded = detail.value;
    return ScreenScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: BackLink.width,
        leading: BackLink(label: tr('applications.heading')),
        actions: [
          if (loaded != null)
            IconButton(
              tooltip: tr('applications.moreActions'),
              icon: const Icon(LucideIcons.ellipsisVertical, size: 20),
              onPressed: () => _showActions(context, loaded),
            ),
        ],
      ),
      body: detail.when(
        loading: () => const ApplicationDetailSkeleton(),
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

/// The ⋯ menu: actions that are not part of the page itself.
Future<void> _showActions(
  BuildContext context,
  ApplicationDetail detail,
) async {
  final colors = context.colors;
  final viewJob = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(LucideIcons.externalLink, color: colors.foreground),
              title: Text(
                tr('applications.viewJob'),
                style: AppTypography.body(
                  fontSize: 16,
                  color: colors.foreground,
                ),
              ),
              onTap: () => Navigator.of(sheet).pop(true),
            ),
            Divider(height: 1, color: colors.border),
            const SizedBox(height: 16),
            AppButton(
              text: tr('applications.cancel'),
              variant: AppButtonVariant.secondary,
              isFullWidth: true,
              onPressed: () => Navigator.of(sheet).pop(),
            ),
          ],
        ),
      ),
    ),
  );
  if (viewJob == true && context.mounted) _showJob(context, detail);
}

Future<void> _showSheet(
  BuildContext context,
  String title,
  List<Widget> children,
) {
  final colors = context.colors;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.display(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    ),
  );
}

// The job as saved when the candidate applied; there is no live job page yet.
void _showJob(BuildContext context, ApplicationDetail detail) {
  final colors = context.colors;
  final item = detail.summary;
  _showSheet(context, item.jobTitle, [
    Text(
      [item.companyName, if (item.location != null) item.location!].join(' · '),
      style: AppTypography.body(fontSize: 14, color: colors.foreground),
    ),
    const SizedBox(height: 8),
    Text(
      tr('applications.jobSnapshotDescription'),
      style: AppTypography.body(fontSize: 13, color: colors.mutedForeground),
    ),
  ]);
}

void _showDocuments(BuildContext context, ApplicationDetail detail) {
  final colors = context.colors;
  final muted = AppTypography.body(fontSize: 13, color: colors.mutedForeground);
  _showSheet(context, tr('applications.documentsSent'), [
    if (detail.attachments.isEmpty)
      Text(tr('applications.noDocuments'), style: muted)
    else
      for (final doc in detail.attachments)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                LucideIcons.fileText,
                size: 18,
                color: colors.mutedForeground,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${tr('applications.attachment.${doc.type}')} · ${doc.fileName}',
                  style: AppTypography.body(
                    fontSize: 14,
                    color: colors.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
    if (detail.message != null && detail.message!.isNotEmpty) ...[
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.muted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          detail.message!,
          style: AppTypography.body(fontSize: 14, color: colors.foreground),
        ),
      ),
    ],
    if (detail.certificates.isNotEmpty) ...[
      const SizedBox(height: 16),
      Text(
        tr('applications.certificates.title'),
        style: AppTypography.display(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
      ),
      const SizedBox(height: 8),
      for (final cert in detail.certificates) _CertificateTile(cert: cert),
      Text(tr('applications.certificates.note'), style: muted),
    ],
  ]);
}

class _Body extends StatelessWidget {
  const _Body({required this.detail, required this.applicationId});

  final ApplicationDetail detail;
  final String applicationId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final item = detail.summary;
    final latest = detail.latestStatusAt;
    final documents = [
      for (final doc in detail.attachments)
        tr('applications.attachment.${doc.type}'),
      if (detail.certificates.isNotEmpty) tr('applications.certificates.title'),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Row(
          children: [
            CompanyAvatar(name: item.companyName, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.jobTitle,
                    style: AppTypography.display(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: item.companyName,
                          style: AppTypography.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                        if (item.location != null)
                          TextSpan(text: ' · ${item.location}'),
                      ],
                    ),
                    style: AppTypography.body(
                      fontSize: 14,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _StatusCard(detail: detail, locale: locale),
        if (item.status == ApplicationConstants.statusOffered) ...[
          const SizedBox(height: 12),
          OfferNotice(text: tr('applications.next.offered')),
        ],
        const SizedBox(height: 12),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _LinkRow(
                title: tr('applications.history.title'),
                subtitle: [
                  if (ApplicationConstants.statuses.contains(item.status))
                    tr('applications.history.${item.status}'),
                  if (latest != null)
                    ApplicationConstants.shortDate(latest, locale),
                  if (detail.version > 0)
                    ApplicationConstants.countText(
                      'applications.updates',
                      detail.version,
                    ),
                ].join(' · '),
                onTap: () =>
                    context.push(AppRoutes.applicationHistory(applicationId)),
              ),
              Divider(height: 1, color: colors.border),
              _LinkRow(
                title: tr('applications.documentsSent'),
                subtitle: documents.isEmpty
                    ? tr('applications.noDocuments')
                    : documents.join(' · '),
                onTap: () => _showDocuments(context, detail),
              ),
              Divider(height: 1, color: colors.border),
              _LinkRow(
                title: tr('applications.jobPosting'),
                subtitle: tr('applications.jobPostingSaved'),
                onTap: () => _showJob(context, detail),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          [
            ApplicationConstants.displayId(applicationId),
            if (item.submittedAt != null)
              tr(
                'applications.card.submitted',
                namedArgs: {
                  'date': ApplicationConstants.dateTime(
                    item.submittedAt!,
                    locale,
                  ),
                },
              ),
          ].join(' · '),
          textAlign: TextAlign.center,
          style: AppTypography.mono(
            fontSize: 12,
            color: colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

/// Status, "Step n of 5 · Next: …" and a five-segment progress bar.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.detail, required this.locale});

  final ApplicationDetail detail;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = detail.summary.status;
    final steps = ApplicationConstants.progressSteps;
    final step = steps.indexOf(status) + 1; // 0 once the process has ended
    final tone = ApplicationConstants.toneColor(status, colors);
    final latest = detail.latestStatusAt;

    final String? subtitle;
    if (step > 0) {
      final stepText = tr(
        'applications.stepOf',
        namedArgs: {'step': '$step', 'total': '${steps.length}'},
      );
      subtitle = step == steps.length
          ? stepText
          : '$stepText · ${tr('applications.nextStatus', namedArgs: {'status': tr(ApplicationConstants.statusKey(steps[step]))})}';
    } else if (status != ApplicationConstants.statusPositionFilled &&
        ApplicationConstants.statuses.contains(status)) {
      subtitle = tr('applications.next.$status');
    } else {
      subtitle = null;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: step > 0
                    ? Text(
                        '$step',
                        style: AppTypography.body(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: tone,
                        ),
                      )
                    : Icon(LucideIcons.x, size: 18, color: tone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(ApplicationConstants.statusKey(status)),
                      style: AppTypography.display(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: AppTypography.body(
                          fontSize: 13,
                          color: colors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              if (latest != null) ...[
                const SizedBox(width: 8),
                Text(
                  ApplicationConstants.shortDate(latest, locale),
                  style: AppTypography.body(
                    fontSize: 13,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
          if (step > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        // Done steps solid, the current one lighter; the
                        // last step (Hired) is done, so the bar is full.
                        color: i < step - 1 || step == steps.length
                            ? tone
                            : i == step - 1
                            ? tone.withValues(alpha: 0.4)
                            : colors.muted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (detail.withdrawalReason != null) ...[
            const SizedBox(height: 12),
            Text(
              tr(
                'applications.withdrawnReason',
                namedArgs: {'reason': detail.withdrawalReason!},
              ),
              style: AppTypography.body(
                fontSize: 13,
                color: colors.mutedForeground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
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
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: AppTypography.body(
                        fontSize: 13,
                        color: colors.mutedForeground,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: colors.mutedForeground,
            ),
          ],
        ),
      ),
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
