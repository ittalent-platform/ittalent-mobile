import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../api/api_error.dart';
import '../../../api/client.dart';
import '../../../auth/auth_notifier.dart';
import '../../../components/common/app_empty_state.dart';
import '../../../components/common/app_error_state.dart';
import '../../../components/common/app_toast.dart';
import '../../../components/common/company_avatar.dart';
import '../../../components/ui/app_card.dart';
import '../../../config/env.dart';
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'jobs_constants.dart';
import 'jobs_format.dart';
import 'jobs_models.dart';
import 'jobs_providers.dart';
import 'widgets/job_company_card.dart';
import 'widgets/job_deadline_notice.dart';
import 'widgets/job_detail_bar.dart';
import 'widgets/job_detail_skeleton.dart';
import 'widgets/job_text_block.dart';

/// UC-BJOB-02: a job's page, with its salary, deadline, texts and company, and
/// a bar that applies to it.
class JobDetailScreen extends ConsumerStatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  static const double logoSize = 56;
  static const double sectionGap = 12;
  static const double factHeight = 32;
  static const int badRequestStatus = 400;

  bool _aboutExpanded = false;

  /// A save or a removal is on its way.
  bool _saving = false;

  /// Whether the job is saved, once the applicant changed it here; until
  /// then it is what the API said (see [jobSavedProvider]).
  bool? _saved;

  /// Back to where the applicant came from; a link that opened the page
  /// straight has nowhere to go back to, so it goes to the list.
  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.jobs);
    }
  }

  Future<void> _share() async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
      ClipboardData(
        text: '${AppEnv.webBaseUrl}${JobConstants.sharePath(widget.jobId)}',
      ),
    );
    showAppToast(messenger, tr('jobs.detail.linkCopied'));
  }

  /// What the button of the bar does. A guest signs in first; an applicant who
  /// already applied goes to their application.
  void _act(JobAction action, String jobId, JobApplication? application) {
    switch (action) {
      case JobAction.apply:
        context.push(AppRoutes.jobApply(jobId));
      case JobAction.signIn:
        // Back to the apply page once signed in, not to the applications.
        context.push(AppRoutes.loginThen(AppRoutes.jobApply(jobId)));
      case JobAction.applied:
        if (application != null) {
          context.go(AppRoutes.applicationDetail(application.id));
        }
      case JobAction.closed:
        context.go(AppRoutes.jobs);
    }
  }

  /// The bookmark of the bar. A guest signs in first, and comes back to this
  /// page; a signed-in applicant saves the job, or takes it out of the saved
  /// ones, and is told so.
  Future<void> _toggleSave(String jobId, bool saved) async {
    if (!ref.read(authNotifierProvider).isAuthenticated) {
      context.push(AppRoutes.loginThen(AppRoutes.jobDetail(jobId)));
      return;
    }
    if (_saving) return;
    final messenger = ScaffoldMessenger.of(context);
    final client = ref.read(apiClientProvider);
    setState(() => _saving = true);
    try {
      if (saved) {
        await client.delete<Map<String, dynamic>>(
          JobConstants.wishlistJobPath(jobId),
        );
      } else {
        await client.post<Map<String, dynamic>>(
          JobConstants.wishlistPath,
          data: {'jobId': jobId},
        );
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = !saved;
      });
      showAppToast(
        messenger,
        tr(saved ? 'jobs.detail.unsaved' : 'jobs.detail.saved'),
      );
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppToast(messenger, tr('jobs.detail.saveFailed'), error: true);
    }
  }

  Widget _topBar() {
    final colors = context.colors;
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: tr('actions.back'),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _back,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.chevronLeft,
                        size: 24,
                        color: colors.fgLink,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        tr('actions.back'),
                        style: AppTypography.body(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colors.fgLink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: tr('jobs.detail.share'),
              onPressed: _share,
              icon: Icon(LucideIcons.share, size: 22, color: colors.foreground),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fact(IconData icon, String label) {
    final colors = context.colors;
    return Container(
      height: factHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(
                fontSize: 13.5,
                color: colors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(JobPosting job, JobCompany? company) {
    final colors = context.colors;
    final now = DateTime.now();
    final posted = JobFormat.postedAgo(job.createdAt, now);
    final rest = [
      ?company?.industry,
      if (posted != null) tr('jobs.card.posted', namedArgs: {'when': posted}),
    ];
    final facts = [
      if (job.location != null) (LucideIcons.mapPin, job.location!),
      if (job.employmentType != null)
        (LucideIcons.clock, JobFormat.employmentLabel(job.employmentType!)),
      if (job.level != null)
        (LucideIcons.chevronUp, JobFormat.levelLabel(job.level!)),
      if (job.openings != null)
        (
          LucideIcons.users,
          JobFormat.countText('jobs.detail.openings', job.openings!),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompanyAvatar(name: job.companyName, size: logoSize, tinted: true),
        const SizedBox(height: sectionGap),
        Text(
          job.title,
          style: AppTypography.display(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            InkWell(
              onTap: job.companyId.isEmpty
                  ? null
                  : () => context.push(AppRoutes.companyDetail(job.companyId)),
              child: Text(
                job.companyName,
                style: AppTypography.body(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: colors.fgLink,
                ),
              ),
            ),
            if (rest.isNotEmpty)
              Text(
                ' · ${rest.join(' · ')}',
                style: AppTypography.body(
                  fontSize: 14.5,
                  color: colors.mutedForeground,
                ),
              ),
          ],
        ),
        if (facts.isNotEmpty) ...[
          const SizedBox(height: sectionGap),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final fact in facts) _fact(fact.$1, fact.$2)],
          ),
        ],
      ],
    );
  }

  Widget _salaryCard(JobPosting job, JobDeadline? deadline) {
    final colors = context.colors;
    final parts = JobFormat.salaryParts(job);
    final showSalary = parts != null || job.salaryNegotiable;
    if (!showSalary && deadline == null) return const SizedBox.shrink();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSalary) ...[
            Text(
              tr('jobs.detail.salary').toUpperCase(),
              style: AppTypography.body(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.72,
                color: colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 4),
            if (parts != null)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: parts.amount,
                      style: AppTypography.display(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                    TextSpan(
                      text: ' ${parts.unit} ${tr('jobs.salary.perMonth')}',
                      style: AppTypography.body(
                        fontSize: 14,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                tr('jobs.salary.negotiable'),
                style: AppTypography.display(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
          ],
          if (deadline != null) ...[
            if (showSalary) const SizedBox(height: sectionGap),
            JobDeadlineNotice(deadline: deadline),
          ],
        ],
      ),
    );
  }

  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTypography.body(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: context.colors.foreground,
        ),
      ),
    );
  }

  /// The description: a few lines with "Read more", so the page does not open
  /// on a wall of text.
  Widget _about(String text) {
    final colors = context.colors;
    final style = AppTypography.body(
      fontSize: 15,
      height: 1.6,
      color: colors.foreground,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(tr('jobs.detail.about')),
        LayoutBuilder(
          builder: (context, constraints) {
            final flat = JobTextBlock.flat(text);
            final painter = TextPainter(
              text: TextSpan(text: flat, style: style),
              maxLines: JobConstants.aboutCollapsedLines,
              textDirection: Directionality.of(context),
            )..layout(maxWidth: constraints.maxWidth);
            final overflows =
                painter.didExceedMaxLines ||
                JobTextBlock.lines(text).length > 1;
            painter.dispose();
            if (_aboutExpanded || !overflows) {
              return JobTextBlock(text: text);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flat,
                  maxLines: JobConstants.aboutCollapsedLines,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
                InkWell(
                  onTap: () => setState(() => _aboutExpanded = true),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      tr('actions.showMore'),
                      style: AppTypography.body(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.fgLink,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _section(String title, String text) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(title),
      JobTextBlock(text: text),
    ],
  );

  Widget _page(JobDetail detail) {
    final job = detail.job;
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final deadline = JobFormat.deadline(job.expiresAt, locale, DateTime.now());
    final company = job.companyId.isEmpty
        ? null
        : ref.watch(jobCompanyProvider(job.companyId));
    final authenticated = ref.watch(authNotifierProvider).isAuthenticated;
    final application = authenticated
        ? ref.watch(jobApplicationProvider(job.id)).value
        : null;

    final saved =
        _saved ??
        (authenticated ? ref.watch(jobSavedProvider(job.id)).value : null) ??
        false;

    final JobAction action;
    if (deadline?.kind == JobDeadlineKind.closed) {
      action = JobAction.closed;
    } else if (!authenticated) {
      action = JobAction.signIn;
    } else if (application != null && !application.canApplyAgain) {
      action = JobAction.applied;
    } else {
      action = JobAction.apply;
    }

    final description = job.description;
    final requirements = job.requirements;
    final benefits = detail.benefits;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: colors.primary,
            onRefresh: () async {
              ref.invalidate(jobDetailProvider(widget.jobId));
              ref.invalidate(jobApplicationProvider(widget.jobId));
              ref.invalidate(jobSavedProvider(widget.jobId));
              _saved = null;
              await ref.read(jobDetailProvider(widget.jobId).future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(job, company?.value),
                  const SizedBox(height: sectionGap),
                  _salaryCard(job, deadline),
                  if (description != null) ...[
                    const SizedBox(height: sectionGap),
                    _about(description),
                  ],
                  if (requirements != null) ...[
                    const SizedBox(height: sectionGap),
                    _section(tr('jobs.detail.requirements'), requirements),
                  ],
                  if (benefits != null) ...[
                    const SizedBox(height: sectionGap),
                    _section(tr('jobs.detail.benefits'), benefits),
                  ],
                  if (job.companyId.isNotEmpty) ...[
                    const SizedBox(height: sectionGap),
                    // While the company loads (or if it cannot) the card shows
                    // the name alone, so the page does not jump.
                    JobCompanyCard(
                      name: job.companyName,
                      company: company?.value,
                      onTap: () =>
                          context.push(AppRoutes.companyDetail(job.companyId)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        JobDetailBar(
          action: action,
          onPressed: () => _act(action, job.id, application),
          // A job that closed cannot be saved any more, only taken out.
          onSave: action == JobAction.closed && !saved
              ? null
              : () => _toggleSave(job.id, saved),
          saved: saved,
          saving: _saving,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(jobDetailProvider(widget.jobId));

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: detail.when(
                skipLoadingOnReload: true,
                loading: () => const JobDetailSkeleton(),
                error: (error, _) {
                  final notAvailable =
                      error is ApiError &&
                      (error.isNotFound ||
                          error.statusCode == badRequestStatus);
                  return notAvailable
                      ? AppEmptyState(
                          icon: const Icon(LucideIcons.briefcase),
                          title: tr('jobs.detail.notAvailable.title'),
                          description: tr(
                            'jobs.detail.notAvailable.description',
                          ),
                          actionText: tr('jobs.detail.notAvailable.browse'),
                          onAction: () => context.go(AppRoutes.jobs),
                        )
                      : AppErrorState(
                          title: tr('jobs.detail.loadError.title'),
                          message: tr('jobs.detail.loadError.description'),
                          retryText: tr('errorState.retry'),
                          onRetry: () =>
                              ref.invalidate(jobDetailProvider(widget.jobId)),
                        );
                },
                data: _page,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
