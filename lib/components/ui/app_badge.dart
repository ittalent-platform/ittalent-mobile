import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

enum BadgeTone { success, warning, info, blocked, peach, error, neutral }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.neutral,
    this.icon,
  });

  final String label;
  final BadgeTone tone;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Color bg;
    Color fg;
    Color border;

    switch (tone) {
      case BadgeTone.success:
        bg = colors.statusSuccessBg;
        fg = colors.statusSuccessFg;
        border = colors.statusSuccessBorder;
        break;
      case BadgeTone.warning:
        bg = colors.statusWarningBg;
        fg = colors.statusWarningFg;
        border = colors.statusWarningBorder;
        break;
      case BadgeTone.info:
        bg = colors.statusInfoBg;
        fg = colors.statusInfoFg;
        border = colors.statusInfoBorder;
        break;
      case BadgeTone.blocked:
        bg = colors.statusBlockedBg;
        fg = colors.statusBlockedFg;
        border = colors.statusBlockedBorder;
        break;
      case BadgeTone.peach:
        bg = colors.statusPeachBg;
        fg = colors.statusPeachFg;
        border = colors.border;
        break;
      case BadgeTone.error:
        bg = colors.statusErrorBg;
        fg = colors.statusErrorFg;
        border = colors.destructive.withValues(alpha: 0.2);
        break;
      case BadgeTone.neutral:
        bg = colors.statusNeutralBg;
        fg = colors.statusNeutralFg;
        border = colors.border;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(color: fg, size: 14),
              child: icon!,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.body(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
