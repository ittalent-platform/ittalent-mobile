import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../companies_format.dart';
import '../companies_models.dart';

/// An open job in the Jobs tab: title, where and what level, salary and the
/// deadline. A tap opens the job's page.
class CompanyJobRow extends StatelessWidget {
  const CompanyJobRow({
    super.key,
    required this.job,
    required this.last,
    required this.onTap,
  });

  final CompanyJob job;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final place = CompanyFormat.jobPlace(job);
    final salaryText = CompanyFormat.salaryText(job);
    final applyBy = CompanyFormat.applyBy(
      job.expiresAt,
      locale,
      DateTime.now(),
    );
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: colors.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.title,
              style: AppTypography.body(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: colors.foreground,
              ),
            ),
            if (place != null) ...[
              const SizedBox(height: 3),
              Text(
                place,
                style: AppTypography.body(
                  fontSize: 13.5,
                  color: colors.mutedForeground,
                ),
              ),
            ],
            if (salaryText != null || applyBy != null) ...[
              const SizedBox(height: 3),
              Text.rich(
                TextSpan(
                  children: [
                    if (salaryText != null)
                      TextSpan(
                        text: salaryText,
                        style: AppTypography.body(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: colors.foreground,
                        ),
                      ),
                    if (applyBy != null)
                      TextSpan(
                        text: salaryText == null ? applyBy : ' · $applyBy',
                        style: AppTypography.body(
                          fontSize: 13.5,
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
    );
  }
}
