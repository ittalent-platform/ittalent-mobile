import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/common/company_avatar.dart';
import '../../../../components/ui/app_badge.dart';
import '../../../../components/ui/app_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../companies_constants.dart';
import '../companies_format.dart';
import '../companies_models.dart';

/// A company in the Companies list: logo tile, name, industry and size, one
/// line about it, where it is, and how many jobs are open.
class CompanyCard extends StatelessWidget {
  const CompanyCard({super.key, required this.company, required this.onTap});

  final CompanySummary company;
  final VoidCallback onTap;

  static const double padding = 14;
  static const int descriptionLines = 3;
  static const double badgeMaxShare = 0.6;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mutedStyle = AppTypography.body(
      fontSize: 13,
      color: colors.mutedForeground,
    );
    final subtitle = CompanyFormat.subtitle(company);
    final description = company.shortDescription;
    final open = company.openRoleCount > 0;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CompanyAvatar(
                name: company.name,
                size: CompanyConstants.cardLogoSize,
                tinted: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.foreground,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
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
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 10),
            Text(
              description,
              maxLines: descriptionLines,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(
                fontSize: 14,
                height: 1.5,
                color: colors.foreground,
              ),
            ),
          ],
          const SizedBox(height: 10),
          // The badge never takes more than [badgeMaxShare] of the line, so a
          // long label (or a large system font) cuts the badge, not the card.
          LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Expanded(
                  child: company.cities.isEmpty
                      ? const SizedBox.shrink()
                      : Row(
                          children: [
                            Icon(
                              LucideIcons.mapPin,
                              size: 14,
                              color: colors.mutedForeground,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                CompanyFormat.cities(company.cities),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: mutedStyle,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * badgeMaxShare,
                  ),
                  child: AppBadge(
                    label: CompanyFormat.openJobs(company.openRoleCount),
                    tone: open ? BadgeTone.success : BadgeTone.neutral,
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
