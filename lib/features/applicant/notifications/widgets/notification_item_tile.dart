import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../notifications_constants.dart';
import '../notifications_providers.dart';
import 'notification_type_icon.dart';

class NotificationItemTile extends StatelessWidget {
  const NotificationItemTile({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
  });

  final NotificationItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isUnread = !item.isRead;
    final isAnnouncement =
        item.type == NotificationConstants.typeSystemAnnouncement;

    return Material(
      color: colors.card,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colors.border.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unread indicator dot (8px) + space
              SizedBox(
                width: 16,
                height: 40,
                child: Center(
                  child: isUnread
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      : const SizedBox(width: 8, height: 8),
                ),
              ),

              // Category Icon Chip (40x40)
              NotificationTypeIcon(type: item.type),
              const SizedBox(width: 12),

              // Body content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: Title + Relative Timestamp
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.foreground,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          NotificationConstants.formatRelativeTime(
                            item.createdAt,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.mutedForeground,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Message text clamped to 2 lines
                    Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.mutedForeground,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // "From ITTalent" pill label for announcements
                    if (isAnnouncement) ...[
                      const SizedBox(height: 6),
                      Text(
                        tr('notifications.announcement.from'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
