import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../components/ui/app_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_typography.dart';

class RemoveUnavailableDialog extends StatelessWidget {
  const RemoveUnavailableDialog({
    super.key,
    required this.onConfirm,
    this.isPending = false,
  });

  final VoidCallback onConfirm;
  final bool isPending;

  static Future<bool?> show(BuildContext context, {required VoidCallback onConfirm}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => RemoveUnavailableDialog(
        onConfirm: () {
          Navigator.of(ctx).pop(true);
          onConfirm();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('savedJobs.dialog.removeUnavailableTitle'),
              style: AppTypography.display(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('savedJobs.dialog.removeUnavailableDescription'),
              style: AppTypography.body(
                fontSize: 14,
                color: colors.mutedForeground,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  text: tr('common.cancel'),
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.sm,
                  onPressed: isPending ? null : () => Navigator.of(context).pop(false),
                ),
                const SizedBox(width: 8),
                AppButton(
                  text: tr('savedJobs.dialog.removeConfirm'),
                  variant: AppButtonVariant.destructive,
                  size: AppButtonSize.sm,
                  isLoading: isPending,
                  onPressed: onConfirm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
