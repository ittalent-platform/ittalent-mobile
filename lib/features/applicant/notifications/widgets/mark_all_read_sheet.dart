import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../components/ui/app_button.dart';
import '../../../../theme/app_colors.dart';

class MarkAllReadSheet extends StatelessWidget {
  const MarkAllReadSheet({super.key, required this.count});

  final int count;

  static Future<bool?> show(BuildContext context, {required int count}) {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.colors.card,
      builder: (_) => MarkAllReadSheet(count: count),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final title = count == 1
        ? tr(
            'notifications.markAllAsReadConfirmTitle_one',
            namedArgs: {'count': '$count'},
          )
        : tr(
            'notifications.markAllAsReadConfirmTitle',
            namedArgs: {'count': '$count'},
          );

    final confirmText = tr(
      'notifications.markAllAsReadConfirmBtn',
      namedArgs: {'count': '$count'},
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.foreground,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('notifications.markAllAsReadConfirmDesc'),
              style: TextStyle(
                fontSize: 14.5,
                color: colors.mutedForeground,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              key: const Key('mark_all_read_confirm_btn'),
              text: confirmText,
              variant: AppButtonVariant.primary,
              isFullWidth: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            AppButton(
              key: const Key('mark_all_read_cancel_btn'),
              text: tr('notifications.cancel'),
              variant: AppButtonVariant.secondary,
              isFullWidth: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
