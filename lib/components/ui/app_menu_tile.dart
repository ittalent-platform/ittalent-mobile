import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class AppMenuTile extends StatelessWidget {
  const AppMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.badgeCount,
    this.badgeText,
    this.trailingChevron = true,
    this.iconBackgroundColor,
    this.iconColor,
    this.textColor,
    this.isDestructive = false,
    this.onTap,
    this.showDivider = true,
    this.dividerColor = const Color(0xFFEFEDE8),
  });

  final IconData icon;
  final String title;
  final int? badgeCount;
  final String? badgeText;
  final bool trailingChevron;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final bool isDestructive;
  final VoidCallback? onTap;
  final bool showDivider;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final effectiveIconBg = isDestructive
        ? colors.statusErrorBg
        : (iconBackgroundColor ?? const Color(0xFFF1EFEA));
    final effectiveIconColor = isDestructive
        ? colors.statusErrorFg
        : (iconColor ?? const Color(0xFF4A4A50));
    final effectiveTextColor = isDestructive
        ? colors.statusErrorFg
        : (textColor ?? const Color(0xFF19191C));
    final effectiveChevron = isDestructive ? false : trailingChevron;

    final displayBadge =
        badgeText ?? (badgeCount != null ? '$badgeCount' : null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(bottom: BorderSide(color: dividerColor, width: 1.0))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: effectiveIconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 17, color: effectiveIconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: effectiveTextColor,
                  ),
                ),
              ),
              if (displayBadge != null) ...[
                Text(
                  displayBadge,
                  style: AppTypography.body(
                    fontSize: 15,
                    color: const Color(0xFF64646B),
                  ),
                ),
                if (effectiveChevron) const SizedBox(width: 8),
              ],
              if (effectiveChevron)
                const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: Color(0xFFB9B8B4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
