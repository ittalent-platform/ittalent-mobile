import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_typography.dart';
import 'apply_style.dart';

enum ApplyPillTone { brand, neutral, warning }

/// A small pill: "Default CV" (brand), "Expired" (neutral) and "Not HTTPS"
/// (warning). Unlike a status badge it has no outline.
class ApplyPill extends StatelessWidget {
  const ApplyPill({
    super.key,
    required this.label,
    this.tone = ApplyPillTone.brand,
    this.icon,
  });

  final String label;
  final ApplyPillTone tone;
  final IconData? icon;

  static const double height = 24;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = switch (tone) {
      ApplyPillTone.brand => (colors.brandTint, colors.fgLink),
      ApplyPillTone.neutral => (colors.border, colors.statusNeutralFg),
      ApplyPillTone.warning => (colors.statusWarningBg, colors.statusWarningFg),
    };
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
