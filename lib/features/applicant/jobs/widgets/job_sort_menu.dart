import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../jobs_query.dart';

/// "Newest ⌄" above the list; opens the sort options.
class JobSortMenu extends StatelessWidget {
  const JobSortMenu({super.key, required this.sort, required this.onSelected});

  final JobSort sort;
  final ValueChanged<JobSort> onSelected;

  static const double iconSize = 16;

  /// `jobs.sort.newest`, `jobs.sort.oldest`, `jobs.sort.salaryHigh`, ...
  static String labelKey(JobSort sort) => 'jobs.sort.${sort.name}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopupMenuButton<JobSort>(
      initialValue: sort,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final option in JobSort.values)
          PopupMenuItem<JobSort>(
            value: option,
            child: Text(tr(labelKey(option))),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr(labelKey(sort)),
            style: AppTypography.body(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            LucideIcons.chevronDown,
            size: iconSize,
            color: colors.foreground,
          ),
        ],
      ),
    );
  }
}
