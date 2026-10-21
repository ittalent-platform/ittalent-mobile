import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../config/routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

/// "‹ Applications" / "‹ Back" link used as the app bar's leading widget.
class BackLink extends StatelessWidget {
  const BackLink({super.key, required this.label});

  final String label;

  static const double width = 160;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.primary;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => context.canPop()
            ? context.pop()
            : context.go(AppRoutes.myApplications),
        icon: Icon(LucideIcons.chevronLeft, size: 20, color: color),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }
}
