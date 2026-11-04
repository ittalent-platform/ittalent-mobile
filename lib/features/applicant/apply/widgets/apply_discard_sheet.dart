import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../components/ui/app_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

/// "Discard this application?" Asks before closing the flow, and says that
/// nothing has been sent. Resolves true to discard, false to keep applying.
Future<bool> showApplyDiscardSheet(BuildContext context, String company) async {
  final colors = context.colors;
  final discard = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: colors.card,
    barrierColor: colors.foreground.withValues(alpha: 0.45),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.input,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              tr('apply.discard.title'),
              style: AppTypography.display(
                fontSize: 20,
                height: 1.25,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr('apply.discard.body', namedArgs: {'company': company}),
              style: AppTypography.body(
                fontSize: 14.5,
                height: 1.5,
                color: colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 14),
            AppButton(
              text: tr('apply.discard.confirm'),
              variant: AppButtonVariant.destructive,
              size: AppButtonSize.lg,
              isFullWidth: true,
              onPressed: () => Navigator.of(sheet).pop(true),
            ),
            const SizedBox(height: 10),
            AppButton(
              text: tr('apply.discard.keep'),
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.lg,
              isFullWidth: true,
              onPressed: () => Navigator.of(sheet).pop(false),
            ),
          ],
        ),
      ),
    ),
  );
  return discard ?? false;
}
