import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_typography.dart';

enum AuthBannerTone { error, warning, info }

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({
    super.key,
    required this.message,
    this.tone = AuthBannerTone.error,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AuthBannerTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final IconData icon;

    switch (tone) {
      case AuthBannerTone.error:
        bgColor = colors.statusErrorBg;
        borderColor = colors.statusErrorFg.withValues(alpha: 0.25);
        textColor = colors.statusErrorFg;
        icon = LucideIcons.triangleAlert;
        break;
      case AuthBannerTone.warning:
        bgColor = colors.statusWarningBg;
        borderColor = colors.statusWarningBorder;
        textColor = colors.statusWarningFg;
        icon = LucideIcons.mail;
        break;
      case AuthBannerTone.info:
        bgColor = colors.statusPeachBg;
        borderColor = colors.statusPeachFg.withValues(alpha: 0.25);
        textColor = colors.statusPeachFg;
        icon = LucideIcons.lock;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.inputRadius,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: AppTypography.body(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(
                      actionLabel!,
                      style: AppTypography.body(
                        fontSize: 13,
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
