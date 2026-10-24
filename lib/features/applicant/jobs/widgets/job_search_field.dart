import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_typography.dart';

/// Search box of the job list. It only looks like an input: tapping it opens
/// the search page, where the keyboard and the suggestions are.
class JobSearchField extends StatelessWidget {
  const JobSearchField({super.key, required this.onTap});

  final VoidCallback onTap;

  static const double iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: tr('home.search.keywordPlaceholder'),
      child: Material(
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.inputRadius,
          side: BorderSide(color: colors.input),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: AppRadius.inputRadius,
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  LucideIcons.search,
                  size: iconSize,
                  color: colors.mutedForeground,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr('home.search.keywordPlaceholder'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      fontSize: 14,
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
