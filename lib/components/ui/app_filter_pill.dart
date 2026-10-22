import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Dropdown-style filter pill ("Status: All") that opens a filter sheet;
/// tinted when it filters.
class AppFilterPill extends StatelessWidget {
  const AppFilterPill({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = active ? colors.primary : colors.foreground;
    return Material(
      color: active ? colors.statusPeachBg : colors.card,
      shape: StadiumBorder(
        side: BorderSide(color: active ? colors.primary : colors.border),
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
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronDown, size: 16, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}
