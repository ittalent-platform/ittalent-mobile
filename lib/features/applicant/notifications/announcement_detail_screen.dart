import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../api/client.dart';
import '../../../components/common/app_error_state.dart';
import '../../../components/layout/screen_scaffold.dart';
import '../../../components/ui/app_skeleton.dart';
import '../../../theme/app_colors.dart';
import 'notifications_constants.dart';
import 'notifications_providers.dart';

final announcementDetailProvider = FutureProvider.autoDispose
    .family<NotificationItem, String>((ref, id) async {
      // First check if it already exists in the feed cache
      final feedState = ref.read(notificationsFeedProvider).asData?.value;
      final cached = feedState?.items.where((e) => e.id == id).firstOrNull;
      if (cached != null) {
        return cached;
      }

      // Otherwise fetch from API
      final res = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>(NotificationConstants.deletePath(id));
      return NotificationItem.fromJson(res.data ?? const {});
    });

class AnnouncementDetailScreen extends ConsumerStatefulWidget {
  const AnnouncementDetailScreen({
    super.key,
    required this.id,
    this.initialItem,
  });

  final String id;
  final NotificationItem? initialItem;

  @override
  ConsumerState<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState
    extends ConsumerState<AnnouncementDetailScreen> {
  bool _hasMarkedRead = false;

  void _markReadIfNeeded(NotificationItem item) {
    if (!_hasMarkedRead && !item.isRead) {
      _hasMarkedRead = true;
      Future.microtask(() async {
        try {
          await ref
              .read(apiClientProvider)
              .patch<dynamic>(NotificationConstants.readPath(item.id));
          if (mounted) {
            ref.read(unreadCountProvider.notifier).decrement(1);
            unawaited(
              ref.read(notificationsFeedProvider.notifier).markAsRead(item.id),
            );
          }
        } catch (_) {}
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncItem = widget.initialItem != null
        ? AsyncData(widget.initialItem!)
        : ref.watch(announcementDetailProvider(widget.id));

    return ScreenScaffold(
      padding: EdgeInsets.zero,
      body: SafeArea(
        child: asyncItem.when(
          loading: () => _buildLoadingSkeleton(context),
          error: (error, _) => AppErrorState(
            title: tr('notifications.error.unavailableTitle'),
            message: tr('notifications.error.unavailableDesc'),
            onRetry: () => ref.refresh(announcementDetailProvider(widget.id)),
          ),
          data: (item) {
            _markReadIfNeeded(item);
            return _buildContent(context, item);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, NotificationItem item) {
    final colors = context.colors;
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final formattedDate = NotificationConstants.formatAnnouncementDateTime(
      item.createdAt,
      locale: locale,
    );

    final backLabelRaw = tr('notifications.actions.backToNotifications');
    final backLabel = backLabelRaw.startsWith('notifications.actions')
        ? 'Notifications'
        : backLabelRaw;

    return Column(
      children: [
        // Top Navigation Bar
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  key: const Key('announcement_back_btn'),
                  onTap: () => context.pop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.chevronLeft,
                          size: 22,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            backLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const Key('announcement_delete_btn'),
                icon: Icon(
                  LucideIcons.trash2,
                  size: 20,
                  color: colors.destructive,
                ),
                onPressed: () async {
                  try {
                    await ref
                        .read(apiClientProvider)
                        .delete<dynamic>(
                          NotificationConstants.deletePath(item.id),
                        );
                    unawaited(
                      ref
                          .read(notificationsFeedProvider.notifier)
                          .deleteNotification(item.id),
                    );
                  } catch (_) {}
                  if (!context.mounted) return;
                  context.pop();
                  _showUndoDeleteSnackBar(context, item);
                },
              ),
            ],
          ),
        ),

        // Body Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header chip & Meta
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.statusPeachBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          LucideIcons.megaphone,
                          color: colors.statusPeachFg,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('notifications.announcement.sender'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.foreground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tr(
                              'notifications.announcement.meta',
                              namedArgs: {'date': formattedDate},
                            ),
                            style: TextStyle(
                              fontSize: 13.5,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Title
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                    height: 1.2,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Body Message
                Text(
                  item.message,
                  style: TextStyle(
                    fontSize: 16,
                    color: colors.foreground,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),

                // Bottom Callout
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.muted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          LucideIcons.info,
                          size: 17,
                          color: colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tr('notifications.announcement.repliesNotPossible'),
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.foreground,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showUndoDeleteSnackBar(BuildContext context, NotificationItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        duration: const Duration(
          seconds: NotificationConstants.undoDurationSeconds,
        ),
        backgroundColor: const Color(0xFF19191C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          tr('notifications.toast.deleted'),
          style: const TextStyle(color: Colors.white, fontSize: 14.5),
        ),
        action: SnackBarAction(
          label: tr('notifications.actions.undo'),
          textColor: const Color(0xFFFF9B73),
          onPressed: () {
            ref.read(notificationsFeedProvider.notifier).undoDelete(item);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppSkeleton(
                width: 44,
                height: 44,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton(width: 100, height: 14),
                  const SizedBox(height: 6),
                  AppSkeleton(width: 160, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          AppSkeleton(width: 240, height: 24),
          const SizedBox(height: 16),
          AppSkeleton(width: double.infinity, height: 14),
          const SizedBox(height: 8),
          AppSkeleton(width: double.infinity, height: 14),
          const SizedBox(height: 8),
          AppSkeleton(width: 180, height: 14),
        ],
      ),
    );
  }
}
