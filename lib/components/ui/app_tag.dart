import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Small filled tag for a plain fact ("Full-time", "Senior"). It carries no
/// status: for a status use `AppBadge`.
class AppTag extends StatelessWidget {
  const AppTag({super.key, required this.label});

  final String label;

  static const double radius = 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        label,
        style: AppTypography.body(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
      ),
    );
  }
}
