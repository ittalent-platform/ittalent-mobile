import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../components/common/company_avatar.dart';
import '../../../../components/ui/app_badge.dart';
import '../../../../components/ui/app_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../jobs_format.dart';
import '../jobs_models.dart';

/// One job of the list: company, title, salary, type and level, dates.
class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job, this.onTap});

  final JobPosting job;
  final VoidCallback? onTap;

  static const double avatarSize = 44;
  static const double badgeMaxWidth = 96;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final salary = JobFormat.salaryAmount(job);
    final posted = JobFormat.postedAgo(job.createdAt, now);
    final applyBy = JobFormat.applyBy(job.expiresAt, locale);
    final meta = [
      if (job.companyName.isNotEmpty) job.companyName,
      ?job.location,
    ].join(' · ');
    final footer = [
      if (posted != null) tr('jobs.card.posted', namedArgs: {'when': posted}),
      ?applyBy,
    ].join(' · ');
    final tags = [
      if (job.employmentType != null)
        JobFormat.employmentLabel(job.employmentType!),
      if (job.level != null) JobFormat.levelLabel(job.level!),
    ];

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanyAvatar(
                name: job.companyName,
                size: avatarSize,
                tinted: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          fontSize: 13,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (job.isNew(now)) ...[
                const SizedBox(width: 8),
                // Bounded, so the badge's flexible label has a width to fill.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: badgeMaxWidth),
                  child: AppBadge(
                    label: tr('jobs.card.new'),
                    tone: BadgeTone.info,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: salary ?? tr('jobs.salary.negotiable'),
                  style: AppTypography.body(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.foreground,
                  ),
                ),
                if (salary != null)
                  TextSpan(
                    text: ' ${tr('jobs.salary.perMonth')}',
                    style: AppTypography.body(
                      fontSize: 14,
                      color: colors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final tag in tags) JobTag(label: tag)],
            ),
          ],
          if (footer.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              footer,
              style: AppTypography.body(
                fontSize: 12,
                color: colors.mutedForeground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small filled tag ("Full-time", "Senior").
class JobTag extends StatelessWidget {
  const JobTag({super.key, required this.label});

  final String label;

  static const double radius = 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        label,
        style: AppTypography.body(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
      ),
    );
  }
}
