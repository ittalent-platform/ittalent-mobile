import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_typography.dart';
import '../jobs_format.dart';

/// The line under the salary: how long the job takes applications. It turns
/// red on the last day, and says the job is closed once the deadline is over.
class JobDeadlineNotice extends StatelessWidget {
  const JobDeadlineNotice({super.key, required this.deadline});

  final JobDeadline deadline;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final today = deadline.kind == JobDeadlineKind.today;
    final closed = deadline.kind == JobDeadlineKind.closed;
    final bg = today ? colors.statusErrorBg : colors.statusWarningBg;
    final fg = today ? colors.statusErrorFg : colors.statusWarningFg;
    final border = today
        ? colors.destructive.withValues(alpha: 0.2)
        : colors.statusWarningBorder;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              closed ? LucideIcons.lock : LucideIcons.clock,
              size: 17,
              color: fg,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              deadline.text,
              style: AppTypography.body(fontSize: 14, height: 1.45, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
