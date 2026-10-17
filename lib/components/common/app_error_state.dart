import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';
import '../ui/app_button.dart';

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.title = 'An error occurred',
    this.onRetry,
    this.retryText = 'Try again',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: colors.statusErrorBg,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: colors.destructive.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.destructive.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.alertCircle,
                  color: colors.statusErrorFg,
                  size: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.display(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.statusErrorFg,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body(
                  fontSize: 13,
                  color: colors.mutedForeground,
                  height: 1.4,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                AppButton(
                  text: retryText,
                  onPressed: onRetry,
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.sm,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
