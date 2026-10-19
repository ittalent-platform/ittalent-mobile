import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

class AppMenuGroup extends StatelessWidget {
  const AppMenuGroup({
    super.key,
    this.title,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title!,
              style: AppTypography.body(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.06 * 12,
                color: const Color(0xFF6F6F76),
              ),
            ),
          ),
        Container(
          margin: margin,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(color: colors.border, width: 1.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}
