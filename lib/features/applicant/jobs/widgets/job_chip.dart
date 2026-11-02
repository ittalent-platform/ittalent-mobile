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

  static const double height = 40;
  static const double closeSize = 14;
  static const double selectedBorderAlpha = 0.4;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = selected || showClose;
    final fg = active ? colors.fgLink : colors.foreground;
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: active ? colors.statusPeachBg : colors.card,
        shape: StadiumBorder(
          side: BorderSide(
            color: active
                ? colors.primary.withValues(alpha: selectedBorderAlpha)
                : colors.border,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          // Not a Container with an alignment: that one fills the width it is
          // given, so a Wrap could not put chips side by side.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: height),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                widthFactor: 1,
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
        ),
      ),
    );
  }
}
