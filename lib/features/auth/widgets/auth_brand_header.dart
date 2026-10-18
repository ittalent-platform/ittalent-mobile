import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/ui/ittalent_monogram.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.showLogo = true,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null) ...[
          IconButton(
            onPressed: onBack,
            icon: const Icon(LucideIcons.chevronLeft, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: colors.foreground,
          ),
          const SizedBox(height: 16),
        ],
        if (showLogo) ...[
          Row(
            children: [
              const ITTalentMonogram(size: 26),
              const SizedBox(width: 8),
              Text(
                'ITTALENT',
                style: AppTypography.display(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.04 * 15,
                  color: colors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        Text(
          title,
          style: AppTypography.display(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: colors.foreground,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: AppTypography.body(
              fontSize: 14,
              color: colors.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }
}
