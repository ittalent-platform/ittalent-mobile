import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/ui/app_button.dart';
import '../../../../theme/app_colors.dart';
import '../notifications_constants.dart';
import '../notifications_providers.dart';
import 'notification_type_icon.dart';

class NotificationActionSheet extends StatelessWidget {
  const NotificationActionSheet({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onToggleRead,
    required this.onDelete,
  });

  final NotificationItem item;
  final VoidCallback? onOpen;
  final VoidCallback onToggleRead;
  final VoidCallback onDelete;

  static Future<void> show(
    BuildContext context, {
    required NotificationItem item,
    required VoidCallback? onOpen,
    required VoidCallback onToggleRead,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: context.colors.card,
      builder: (_) => NotificationActionSheet(
        item: item,
        onOpen: onOpen,
        onToggleRead: onToggleRead,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isAnnouncement =
        item.type == NotificationConstants.typeSystemAnnouncement;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview header
            Row(
              children: [
                NotificationTypeIcon(type: item.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.foreground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.mutedForeground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: colors.border.withValues(alpha: 0.6)),

            // Action list
            if (onOpen != null) ...[
              _buildActionTile(
                key: const Key('notification_action_open'),
                icon: LucideIcons.externalLink,
                label: isAnnouncement
                    ? tr('notifications.actions.openAnnouncement')
                    : tr('notifications.actions.openApplication'),
                textColor: colors.foreground,
                onTap: () {
                  Navigator.of(context).pop();
                  onOpen?.call();
                },
              ),
              Divider(height: 1, color: colors.border.withValues(alpha: 0.6)),
            ],

            _buildActionTile(
              key: const Key('notification_action_toggle_read'),
              icon: item.isRead ? LucideIcons.mail : LucideIcons.check,
              label: item.isRead
                  ? tr('notifications.actions.markAsUnread')
                  : tr('notifications.actions.markAsRead'),
              textColor: colors.foreground,
              onTap: () {
                Navigator.of(context).pop();
                onToggleRead();
              },
            ),
            Divider(height: 1, color: colors.border.withValues(alpha: 0.6)),

            _buildActionTile(
              key: const Key('notification_action_delete'),
              icon: LucideIcons.trash2,
              label: tr('notifications.actions.delete'),
              textColor: colors.destructive,
              onTap: () {
                Navigator.of(context).pop();
                onDelete();
              },
            ),
            const SizedBox(height: 16),

            AppButton(
              key: const Key('notification_action_cancel'),
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

  Widget _buildActionTile({
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
