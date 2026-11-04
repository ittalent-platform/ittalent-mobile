import 'package:flutter/material.dart';

import '../../../../components/common/company_avatar.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../apply_models.dart';

/// The job being applied to, on top of every step: the company's logo, the
/// title, and "Company · Place".
class ApplyJobTile extends StatelessWidget {
  const ApplyJobTile({super.key, required this.job});

  final ApplyJob job;

  static const double logoSize = 44;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtitle = [
      job.companyName,
      job.location,
    ].whereType<String>().where((part) => part.isNotEmpty).join(' · ');
    return Row(
      children: [
        CompanyAvatar(name: job.companyName, size: logoSize, tinted: true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: 2),
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
          ),
        ),
      ],
    );
  }
}
