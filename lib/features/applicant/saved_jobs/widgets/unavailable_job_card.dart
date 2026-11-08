import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/ui/app_card.dart';
import '../../../../components/ui/app_tag.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../../jobs/jobs_format.dart';
import '../saved_jobs_models.dart';

class UnavailableJobCard extends StatelessWidget {
  const UnavailableJobCard({
    super.key,
    required this.item,
    required this.onRequestRemove,
    this.isRemoving = false,
  });

  final SavedJobItem item;
  final ValueChanged<SavedJobItem> onRequestRemove;
  final bool isRemoving;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final savedAgo = JobFormat.postedAgo(item.savedAt, now);

    return Opacity(
      opacity: isRemoving ? 0.4 : 1.0,
      child: AppCard(
        backgroundColor: colors.muted.withValues(alpha: 0.15),
        borderColor: colors.border.withValues(alpha: 0.6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.ban,
                    size: 20,
                    color: colors.mutedForeground,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('savedJobs.unavailable.title'),
                        style: AppTypography.display(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr('savedJobs.unavailable.description'),
                        style: AppTypography.body(
                          fontSize: 13,
                          color: colors.mutedForeground,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: colors.border.withValues(alpha: 0.6), height: 1),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTag(label: tr('savedJobs.unavailable.tag')),
                    if (savedAgo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        tr(
                          'savedJobs.card.savedTime',
                          namedArgs: {'time': savedAgo},
                        ),
                        style: AppTypography.body(
                          fontSize: 12,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
                Material(
                  color: colors.statusPeachBg,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: isRemoving ? null : () => onRequestRemove(item),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        LucideIcons.heart,
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
      ),
    );
  }
}
