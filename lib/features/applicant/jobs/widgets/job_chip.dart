import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

/// Pill for a choice ([selected] tints it) or for an applied filter, which
/// shows a ✕ ([showClose]) and is removed by tapping it.
class JobChip extends StatelessWidget {
  const JobChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.showClose = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool showClose;

  static const double closeSize = 16;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = selected ? colors.primary : colors.foreground;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.statusPeachBg : colors.card,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? colors.primary : colors.border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
                if (showClose) ...[
                  const SizedBox(width: 6),
                  Icon(LucideIcons.x, size: closeSize, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
