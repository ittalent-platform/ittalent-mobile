import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/common/company_avatar.dart';
import '../../../../components/ui/app_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../jobs_format.dart';
import '../jobs_models.dart';

/// The company under a job: what it does, how big it is and how many jobs it
/// has open. Tapping it opens the company page.
class JobCompanyCard extends StatelessWidget {
  const JobCompanyCard({
    super.key,
    required this.name,
    required this.onTap,
    this.company,
  });

  final String name;

  /// Null while the company is not known: the card then shows its name only.
  final JobCompany? company;
  final VoidCallback onTap;

  static const double avatarSize = 44;

  /// "Fintech · 100–200 people · 8 open jobs"; a part that is not known is
  /// left out.
  static String subtitle(JobCompany company) => [
    ?company.industry,
    if (company.companySize != null)
      tr(
        'home.companies.size',
        namedArgs: {'size': company.companySize!.replaceAll('-', '–')},
      ),
    JobFormat.countText('jobs.detail.openJobs', company.openRoleCount),
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final info = company == null ? null : subtitle(company!);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CompanyAvatar(name: name, size: avatarSize, tinted: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.foreground,
                  ),
                ),
                if (info != null && info.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    info,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      fontSize: 13.5,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            LucideIcons.chevronRight,
            size: 20,
            color: colors.mutedForeground,
          ),
        ],
      ),
    );
  }
}
