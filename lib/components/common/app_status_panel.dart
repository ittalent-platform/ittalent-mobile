import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';
import '../ui/app_badge.dart';

class AppStatusPanel extends StatelessWidget {
  const AppStatusPanel({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.tone = BadgeTone.neutral,
    this.actions,
    this.footerNote,
  });

  final String title;
  final String description;
  final Widget icon;
  final BadgeTone tone;
  final Widget? actions;
  final String? footerNote;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Color discBg;
    Color discFg;

    switch (tone) {
      case BadgeTone.success:
        discBg = colors.statusSuccessBg;
        discFg = colors.statusSuccessFg;
        break;
      case BadgeTone.warning:
        discBg = colors.statusWarningBg;
        discFg = colors.statusWarningFg;
        break;
      case BadgeTone.info:
        discBg = colors.statusInfoBg;
        discFg = colors.statusInfoFg;
        break;
      case BadgeTone.blocked:
        discBg = colors.statusBlockedBg;
        discFg = colors.statusBlockedFg;
        break;
      case BadgeTone.peach:
        discBg = colors.statusPeachBg;
        discFg = colors.statusPeachFg;
        break;
      case BadgeTone.error:
        discBg = colors.statusErrorBg;
        discFg = colors.statusErrorFg;
        break;
      case BadgeTone.neutral:
        discBg = colors.muted;
        discFg = colors.mutedForeground;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: discBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: IconTheme(
              data: IconThemeData(color: discFg, size: 28),
              child: icon,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.display(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTypography.body(
              fontSize: 14,
              color: colors.mutedForeground,
              height: 1.4,
            ),
          ),
          if (actions != null) ...[
            const SizedBox(height: 20),
            actions!,
          ],
          if (footerNote != null) ...[
            const SizedBox(height: 14),
            Text(
              footerNote!,
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 12,
                color: colors.mutedForeground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
