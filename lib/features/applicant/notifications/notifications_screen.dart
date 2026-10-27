import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/common/app_empty_state.dart';
import '../../../components/common/app_error_state.dart';
import '../../../components/layout/screen_scaffold.dart';
import '../../../components/ui/app_button.dart';
import '../../../components/ui/app_skeleton.dart';
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import 'notifications_constants.dart';
import 'notifications_providers.dart';
import 'widgets/notification_item_tile.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final activeTab = ref.watch(notificationTabProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final feedAsync = ref.watch(notificationsFeedProvider);

    return ScreenScaffold(
      padding: EdgeInsets.zero,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header Area
          Container(
            color: colors.background,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('notifications.title'),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: colors.foreground,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        unreadCount > 0
                            ? tr(
                                'notifications.unreadCount',
                                namedArgs: {'count': '$unreadCount'},
                              )
                            : tr('notifications.allCaughtUp'),
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.mutedForeground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('notification_more_actions_btn'),
                  icon: Icon(
                    LucideIcons.ellipsis,
                    color: colors.mutedForeground,
                    size: 20,
                  ),
                  onPressed: () {
                    // Actions sheet will be fully wired in PR 3
                  },
                ),
              ],
            ),
          ),

          // Custom Tabs Bar
          _buildTabsBar(context, ref, activeTab, feedAsync.asData?.value),

          // Notification List or State views
          Expanded(
            child: feedAsync.when(
              loading: () => _buildLoadingSkeleton(),
              error: (error, _) => AppErrorState(
                title: tr('notifications.error.loadTitle'),
                message: tr('notifications.error.loadDesc'),
                onRetry: () =>
                    ref.read(notificationsFeedProvider.notifier).refresh(),
              ),
              data: (feedState) =>
                  _buildFeedContent(context, ref, feedState, activeTab),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsBar(
    BuildContext context,
    WidgetRef ref,
    String activeTab,
    NotificationsFeedState? feedState,
  ) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabItem(
              context,
              ref,
              tabKey: NotificationConstants.tabAll,
              label: tr('notifications.tabs.all'),
              count: activeTab == NotificationConstants.tabAll
                  ? feedState?.total
                  : null,
              isActive: activeTab == NotificationConstants.tabAll,
            ),
            const SizedBox(width: 16),
            _buildTabItem(
              context,
              ref,
              tabKey: NotificationConstants.tabUnread,
              label: tr('notifications.tabs.unread'),
              count: ref.watch(unreadCountProvider),
              isActive: activeTab == NotificationConstants.tabUnread,
            ),
            const SizedBox(width: 16),
            _buildTabItem(
              context,
              ref,
              tabKey: NotificationConstants.tabAnnouncements,
              label: tr('notifications.tabs.announcements'),
              count: activeTab == NotificationConstants.tabAnnouncements
                  ? feedState?.total
                  : null,
              isActive: activeTab == NotificationConstants.tabAnnouncements,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context,
    WidgetRef ref, {
    required String tabKey,
    required String label,
    required int? count,
    required bool isActive,
  }) {
    final colors = context.colors;

    return InkWell(
      key: Key('notification_tab_$tabKey'),
      onTap: () {
        ref.read(notificationTabProvider.notifier).selectTab(tabKey);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? colors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? colors.foreground : colors.mutedForeground,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? colors.primary.withValues(alpha: 0.12)
                      : colors.muted.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? colors.primary : colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(width: 180, height: 14),
                    const SizedBox(height: 8),
                    AppSkeleton(width: double.infinity, height: 12),
                    const SizedBox(height: 4),
                    AppSkeleton(width: 220, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedContent(
    BuildContext context,
    WidgetRef ref,
    NotificationsFeedState state,
    String activeTab,
  ) {
    final colors = context.colors;
    final items = state.items;

    if (items.isEmpty) {
      if (activeTab == NotificationConstants.tabUnread) {
        return AppEmptyState(
          icon: const Icon(LucideIcons.checkCheck),
          title: tr('notifications.empty.allCaughtUp'),
          description: tr('notifications.empty.allCaughtUpDesc'),
        );
      } else if (activeTab == NotificationConstants.tabAnnouncements) {
        return AppEmptyState(
          icon: const Icon(LucideIcons.megaphone),
          title: tr('notifications.empty.noAnnouncements'),
          description: tr('notifications.empty.noAnnouncementsDesc'),
        );
      } else {
        return AppEmptyState(
          icon: const Icon(LucideIcons.bell),
          title: tr('notifications.empty.noNotifications'),
          description: tr('notifications.empty.noNotificationsDesc'),
          actionText: tr('notifications.actions.browseJobs'),
          onAction: () => context.go(AppRoutes.jobs),
        );
      }
    }

    // Group items by day
    final isAnnouncements = activeTab == NotificationConstants.tabAnnouncements;
    final Map<String, List<NotificationItem>> groups = {};
    for (final item in items) {
      final g = NotificationConstants.groupForDate(
        item.createdAt,
        isAnnouncementsTab: isAnnouncements,
      );
      groups.putIfAbsent(g, () => []).add(item);
    }

    final groupKeys = groups.keys.toList();

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () => ref.read(notificationsFeedProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: groupKeys.length + 1,
        itemBuilder: (context, index) {
          if (index == groupKeys.length) {
            // End of list controls
            return _buildListFooter(context, ref, state, activeTab);
          }

          final groupKey = groupKeys[index];
          final groupItems = groups[groupKey]!;

          String groupLabel;
          switch (groupKey) {
            case NotificationConstants.groupToday:
              groupLabel = tr('notifications.groups.today');
              break;
            case NotificationConstants.groupYesterday:
              groupLabel = tr('notifications.groups.yesterday');
              break;
            case NotificationConstants.groupThisMonth:
              groupLabel = tr('notifications.groups.thisMonth');
              break;
            case NotificationConstants.groupEarlier:
            default:
              groupLabel = tr('notifications.groups.earlier');
              break;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  groupLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.mutedForeground,
                  ),
                ),
              ),
              ...groupItems.map((item) {
                return NotificationItemTile(
                  key: Key('notification_item_${item.id}'),
                  item: item,
                  onTap: () async {
                    if (!item.isRead) {
                      await ref
                          .read(notificationsFeedProvider.notifier)
                          .markAsRead(item.id);
                    }
                    if (!context.mounted) return;
                    if (item.actionUrl != null && item.actionUrl!.isNotEmpty) {
                      unawaited(context.push(item.actionUrl!));
                    }
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListFooter(
    BuildContext context,
    WidgetRef ref,
    NotificationsFeedState state,
    String activeTab,
  ) {
    final colors = context.colors;
    final isAnnouncements = activeTab == NotificationConstants.tabAnnouncements;

    if (isAnnouncements && !state.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(
          child: Text(
            tr('notifications.announcement.allAnnouncementsSeen'),
            style: TextStyle(fontSize: 13, color: colors.mutedForeground),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Text(
            tr(
              'notifications.showingCount',
              namedArgs: {
                'shown': '${state.items.length}',
                'total': '${state.total}',
              },
            ),
            style: TextStyle(fontSize: 13, color: colors.mutedForeground),
          ),
          if (state.hasMore) ...[
            const SizedBox(height: 12),
            AppButton(
              key: const Key('notification_show_older_btn'),
              variant: AppButtonVariant.outline,
              text: tr('notifications.showOlder'),
              isLoading: state.isLoadingMore,
              onPressed: () {
                ref.read(notificationsFeedProvider.notifier).loadMore();
              },
            ),
          ],
        ],
      ),
    );
  }
}
