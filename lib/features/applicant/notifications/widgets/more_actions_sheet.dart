import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/ui/app_button.dart';
import '../../../../theme/app_colors.dart';

enum MoreNotificationAction { markAllAsRead, deleteAll }

class MoreActionsSheet extends StatelessWidget {
  const MoreActionsSheet({
    super.key,
    required this.unreadCount,
    required this.totalCount,
    required this.onAction,
  });

  final int unreadCount;
  final int totalCount;
  final ValueChanged<MoreNotificationAction> onAction;

  static Future<void> show(
    BuildContext context, {
    required int unreadCount,
    required int totalCount,
    required ValueChanged<MoreNotificationAction> onAction,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.colors.card,
      builder: (_) => MoreActionsSheet(
        unreadCount: unreadCount,
        totalCount: totalCount,
        onAction: onAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('notifications.title'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.foreground,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: colors.border.withValues(alpha: 0.6)),

            if (unreadCount > 0) ...[
              _buildTile(
                key: const Key('more_action_mark_all_read'),
                icon: LucideIcons.checkCheck,
                label: tr('notifications.markAllAsRead'),
                textColor: colors.foreground,
                onTap: () {
                  Navigator.of(context).pop();
                  onAction(MoreNotificationAction.markAllAsRead);
                },
              ),
              Divider(height: 1, color: colors.border.withValues(alpha: 0.6)),
            ],

            if (totalCount > 0) ...[
              _buildTile(
                key: const Key('more_action_delete_all'),
                icon: LucideIcons.trash2,
                label: tr('notifications.deleteAll'),
                textColor: colors.destructive,
                onTap: () {
                  Navigator.of(context).pop();
                  onAction(MoreNotificationAction.deleteAll);
                },
              ),
            ],
            const SizedBox(height: 16),

            AppButton(
              key: const Key('more_action_cancel'),
              text: tr('notifications.cancel'),
              variant: AppButtonVariant.secondary,
              isFullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    Key? key,
    required IconData icon,
    required String label,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textColor),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
