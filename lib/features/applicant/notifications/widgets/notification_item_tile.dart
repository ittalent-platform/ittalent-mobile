import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../theme/app_colors.dart';
import '../notifications_constants.dart';
import '../notifications_providers.dart';
import 'notification_type_icon.dart';

class NotificationItemTile extends StatefulWidget {
  const NotificationItemTile({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.onToggleRead,
    this.onDelete,
    this.initiallySwiped = false,
  });

  final NotificationItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleRead;
  final VoidCallback? onDelete;
  final bool initiallySwiped;

  @override
  State<NotificationItemTile> createState() => _NotificationItemTileState();
}

class _NotificationItemTileState extends State<NotificationItemTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  double _dragExtent = 0;
  static const double _actionExtent = 152.0;

  @override
  void initState() {
    super.initState();
    _dragExtent = widget.initiallySwiped ? -_actionExtent : 0;
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        )..addListener(() {
          setState(() {
            _dragExtent = _animation.value;
          });
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _animation = Tween<double>(
      begin: _dragExtent,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward(from: 0);
  }

  void close() {
    if (_dragExtent != 0) {
      _animateTo(0);
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent = (_dragExtent + details.primaryDelta!).clamp(
        -_actionExtent,
        0.0,
      );
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragExtent < -_actionExtent / 2) {
      _animateTo(-_actionExtent);
    } else {
      _animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final item = widget.item;
    final isUnread = !item.isRead;
    final isAnnouncement =
        item.type == NotificationConstants.typeSystemAnnouncement;

    final readKey = item.isRead
        ? 'notifications.actions.unread'
        : 'notifications.actions.read';
    final readTextRaw = tr(readKey);
    final readLabel = readTextRaw.startsWith('notifications.actions')
        ? (item.isRead ? 'Unread' : 'Read')
        : readTextRaw;

    final deleteTextRaw = tr('notifications.actions.delete');
    final deleteLabel = deleteTextRaw.startsWith('notifications.actions')
        ? 'Delete'
        : deleteTextRaw;

    return Stack(
      children: [
        // Background Swipe Action Tray (only rendered during active swipe reveal)
        if (_dragExtent < 0)
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Read / Unread Action
                InkWell(
                  key: Key('notification_swipe_read_${item.id}'),
                  onTap: () {
                    close();
                    widget.onToggleRead?.call();
                  },
                  child: Container(
                    width: 76,
                    color: const Color(0xFF2A55A8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.isRead ? LucideIcons.mail : LucideIcons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              readLabel,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Delete Action
                InkWell(
                  key: Key('notification_swipe_delete_${item.id}'),
                  onTap: () {
                    close();
                    widget.onDelete?.call();
                  },
                  child: Container(
                    width: 76,
                    color: const Color(0xFFB42318),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.trash2,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              deleteLabel,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Foreground Tile Content
        Transform.translate(
          offset: Offset(_dragExtent, 0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            child: Material(
              color: isUnread ? colors.statusPeachBg : colors.card,
              child: InkWell(
                onTap: () {
                  if (_dragExtent < -10) {
                    close();
                  } else {
                    widget.onTap?.call();
                  }
                },
                onLongPress: widget.onLongPress,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
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
            ),
          ),
        ),
      ],
    );
  }
}
