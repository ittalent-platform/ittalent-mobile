import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/ui/app_badge.dart';
import '../../../../components/ui/app_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../applications_constants.dart';
import '../applications_providers.dart';

/// First characters of an ISO timestamp are the calendar date (YYYY-MM-DD).
const int _isoDateLength = 10;

class ApplicationCard extends StatelessWidget {
  const ApplicationCard({super.key, required this.item, this.onTap});

  final ApplicationItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final submitted = item.submittedAt?.toLocal().toIso8601String();
    final card = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.jobTitle,
            style: AppTypography.display(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  item.companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: AppBadge(
                  label: tr(ApplicationConstants.statusKey(item.status)),
                  tone: ApplicationConstants.badgeToneForStatus(item.status),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (item.location != null) ...[
                Icon(
                  LucideIcons.mapPin,
                  size: 14,
                  color: colors.mutedForeground,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.location!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      fontSize: 12,
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ] else
                const Spacer(),
              if (submitted != null) ...[
                Icon(
                  LucideIcons.calendar,
                  size: 14,
                  color: colors.mutedForeground,
                ),
                const SizedBox(width: 4),
                Text(
                  submitted.substring(0, _isoDateLength),
                  style: AppTypography.body(
                    fontSize: 12,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
    return onTap == null ? card : InkWell(onTap: onTap, child: card);
  }
}
