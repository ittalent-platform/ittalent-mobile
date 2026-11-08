import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../components/common/company_avatar.dart';
import '../../../../components/ui/app_button.dart';
import '../../../../components/ui/app_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../jobs/jobs_format.dart';
import '../saved_jobs_models.dart';

class SavedJobCard extends StatelessWidget {
  const SavedJobCard({
    super.key,
    required this.item,
    required this.onRemove,
    this.onTap,
    this.onApply,
    this.isRemoving = false,
  });

  final SavedJobItem item;
  final ValueChanged<SavedJobItem> onRemove;
  final VoidCallback? onTap;
  final VoidCallback? onApply;
  final bool isRemoving;

  String? _formatSalary(BuildContext context) {
    if (item.salaryNegotiable) {
      return tr('jobs.salary.negotiable');
    }
    if (!item.hasSalary) return null;

    final min = (item.salaryMin ?? 0) > 0 ? item.salaryMin! : null;
    final max = (item.salaryMax ?? 0) > 0 ? item.salaryMax! : null;
    final vnd = item.currency == 'VND';

    String number(num value) {
      if (vnd) {
        final text = (value / 1000000).toStringAsFixed(1);
        return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
      }
      return value.round().toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
    }

    final unit = vnd ? 'M ${item.currency}' : ' ${item.currency}';
    if (min != null && max != null) {
      return min == max
          ? '${number(min)}$unit'
          : '${number(min)}–${number(max)}$unit';
    }
    if (min != null) {
      return tr(
        'jobs.salary.from',
        namedArgs: {'amount': '${number(min)}$unit'},
      );
    }
    return tr(
      'jobs.salary.upTo',
      namedArgs: {'amount': '${number(max!)}$unit'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final companyName =
        item.enterprise?.name.trim().isNotEmpty == true
            ? item.enterprise!.name.trim()
            : tr('savedJobs.card.companyFallback');

    final locationText = [
      companyName,
      if (item.location != null && item.location!.isNotEmpty) item.location!,
    ].join(' · ');

    final salaryText = _formatSalary(context);
    final isVndSalary =
        item.currency == 'VND' && !item.salaryNegotiable && item.hasSalary;
    final savedAgo = JobFormat.postedAgo(item.savedAt, now);
    final deadlineText =
        item.expiresAt != null
            ? JobFormat.applyBy(
              item.expiresAt,
              Localizations.localeOf(context).toString(),
              now,
            )
            : null;

    final meta = [
      if (savedAgo != null)
        tr('savedJobs.card.savedTime', namedArgs: {'time': savedAgo}),
      if (item.isClosingSoon) tr('savedJobs.card.closesIn2Days'),
      ?deadlineText,
    ].join(' · ');

    return Opacity(
      opacity: isRemoving ? 0.4 : 1.0,
      child: AppCard(
        onTap: isRemoving ? null : onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CompanyAvatar(name: companyName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title ?? tr('savedJobs.card.jobTitleFallback'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.display(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locationText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          fontSize: 13,
                          color: colors.mutedForeground,
                        ),
                      ),
                      if (salaryText != null) ...[
                        const SizedBox(height: 6),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: salaryText,
                                style: AppTypography.body(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: colors.foreground,
                                ),
                              ),
                              if (isVndSalary)
                                TextSpan(
                                  text: ' ${tr('jobs.salary.perMonth')}',
                                  style: AppTypography.body(
                                    fontSize: 12,
                                    color: colors.mutedForeground,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppButton(
                      text: tr('savedJobs.card.apply'),
                      size: AppButtonSize.sm,
                      onPressed: isRemoving ? null : (onApply ?? onTap),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: colors.statusPeachBg,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: isRemoving ? null : () => onRemove(item),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.favorite,
                            size: 18,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                meta,
                style: AppTypography.body(
                  fontSize: 12,
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
