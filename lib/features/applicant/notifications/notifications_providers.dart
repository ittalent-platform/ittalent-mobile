import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/client.dart';
import 'notifications_constants.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.category = 'info',
    this.actionUrl,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final String category;
  final String? actionUrl;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? category,
    String? actionUrl,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      category: category ?? this.category,
      actionUrl: actionUrl ?? this.actionUrl,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? NotificationConstants.typeAccountAlert,
      category: json['category'] as String? ?? 'info',
      actionUrl: json['actionUrl'] as String? ?? json['action_url'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? json['is_read'] as bool? ?? false,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : (json['read_at'] != null
                ? DateTime.tryParse(json['read_at'].toString())
                : null),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class NotificationsPage {
  const NotificationsPage({
    required this.items,
    required this.unreadCount,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<NotificationItem> items;
  final int unreadCount;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory NotificationsPage.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>?) ?? const [];
    return NotificationsPage(
      items: list
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? NotificationConstants.pageSize,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}

class NotificationsFeedState {
  const NotificationsFeedState({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.unreadCount,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<NotificationItem> items;
  final int page;
  final int totalPages;
  final int total;
  final int unreadCount;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  bool get hasMore => page < totalPages;

  NotificationsFeedState copyWith({
    List<NotificationItem>? items,
    int? page,
    int? totalPages,
    int? total,
    int? unreadCount,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) {
    return NotificationsFeedState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}

class NotificationTabNotifier extends Notifier<String> {
  @override
  String build() => NotificationConstants.tabAll;

  void selectTab(String tab) {
    state = tab;
  }
}

final notificationTabProvider =
    NotifierProvider.autoDispose<NotificationTabNotifier, String>(
      NotificationTabNotifier.new,
    );

class UnreadCountNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> fetch() async {
    try {
      final res = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>(NotificationConstants.unreadCountPath);
      state = res.data?['unreadCount'] as int? ?? 0;
    } catch (_) {}
  }

  void setCount(int count) {
    state = count < 0 ? 0 : count;
  }

  void decrement([int amount = 1]) {
    state = (state - amount) < 0 ? 0 : (state - amount);
  }

  void increment([int amount = 1]) {
    state = state + amount;
  }

  void clear() {
    state = 0;
  }
}

final unreadCountProvider = NotifierProvider<UnreadCountNotifier, int>(
  UnreadCountNotifier.new,
);

class NotificationsFeedNotifier extends AsyncNotifier<NotificationsFeedState> {
  @override
  Future<NotificationsFeedState> build() async {
    final tab = ref.watch(notificationTabProvider);
    final pageData = await _fetch(tab, 1);
    if (ref.mounted) {
      unawaited(
        Future.microtask(() {
          if (ref.mounted) {
            ref
                .read(unreadCountProvider.notifier)
                .setCount(pageData.unreadCount);
          }
        }),
      );
    }
    return NotificationsFeedState(
      items: pageData.items,
      page: pageData.page,
      totalPages: pageData.totalPages,
      total: pageData.total,
      unreadCount: pageData.unreadCount,
    );
  }

  Future<NotificationsPage> _fetch(String tab, int page) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': NotificationConstants.pageSize,
    };
    if (tab == NotificationConstants.tabUnread) {
      params['isRead'] = false;
    } else if (tab == NotificationConstants.tabAnnouncements) {
      params['type'] = NotificationConstants.typeSystemAnnouncement;
    }

    final res = await ref
        .read(apiClientProvider)
        .get<Map<String, dynamic>>(
          NotificationConstants.listPath,
          queryParameters: params,
        );
    return NotificationsPage.fromJson(res.data ?? const {});
  }

  Future<void> refresh() async {
    final tab = ref.read(notificationTabProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final pageData = await _fetch(tab, 1);
      ref.read(unreadCountProvider.notifier).setCount(pageData.unreadCount);
      return NotificationsFeedState(
        items: pageData.items,
        page: pageData.page,
        totalPages: pageData.totalPages,
        total: pageData.total,
        unreadCount: pageData.unreadCount,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final tab = ref.read(notificationTabProvider);
      final next = await _fetch(tab, current.page + 1);
      final known = current.items.map((e) => e.id).toSet();
      state = AsyncData(
        current.copyWith(
          items: [
            ...current.items,
            ...next.items.where((e) => !known.contains(e.id)),
          ],
          page: next.page,
          totalPages: next.totalPages,
          total: next.total,
          unreadCount: next.unreadCount,
          isLoadingMore: false,
        ),
      );
      ref.read(unreadCountProvider.notifier).setCount(next.unreadCount);
    } catch (_) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreFailed: true),
      );
    }
  }

  Future<void> markAsRead(String id) async {
    final current = state.value;
    if (current == null) return;

    final index = current.items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final original = current.items[index];
    if (original.isRead) return;

    final tab = ref.read(notificationTabProvider);
    final updatedList = [...current.items];
    if (tab == NotificationConstants.tabUnread) {
      updatedList.removeAt(index);
    } else {
      updatedList[index] = original.copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
    }

    final newUnread = (current.unreadCount - 1).clamp(0, 999999);
    final newTotal = tab == NotificationConstants.tabUnread
        ? (current.total - 1).clamp(0, 999999)
        : current.total;

    state = AsyncData(
      current.copyWith(
        items: updatedList,
        unreadCount: newUnread,
        total: newTotal,
      ),
    );
    ref.read(unreadCountProvider.notifier).decrement(1);

    try {
      await ref
          .read(apiClientProvider)
          .patch<dynamic>(NotificationConstants.readPath(id));
    } catch (e) {
      // Revert on error
      state = AsyncData(current);
      ref.read(unreadCountProvider.notifier).setCount(current.unreadCount);
      rethrow;
    }
  }

  Future<void> markAllAsRead({String? before}) async {
    final current = state.value;
    if (current == null) return;

    final tab = ref.read(notificationTabProvider);
    final updatedList = tab == NotificationConstants.tabUnread
        ? <NotificationItem>[]
        : current.items
              .map((i) => i.copyWith(isRead: true, readAt: DateTime.now()))
              .toList();

    state = AsyncData(
      current.copyWith(
        items: updatedList,
        unreadCount: 0,
        total: tab == NotificationConstants.tabUnread ? 0 : current.total,
      ),
    );
    ref.read(unreadCountProvider.notifier).clear();

    try {
      await ref
          .read(apiClientProvider)
          .patch<dynamic>(
            NotificationConstants.readAllPath,
            queryParameters: before != null ? {'before': before} : null,
          );
    } catch (e) {
      state = AsyncData(current);
      ref.read(unreadCountProvider.notifier).setCount(current.unreadCount);
      rethrow;
    }
  }

  Future<void> deleteNotification(String id) async {
    final current = state.value;
    if (current == null) return;

    final index = current.items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final target = current.items[index];
    final wasUnread = !target.isRead;
    final updatedList = [...current.items]..removeAt(index);
    final newTotal = (current.total - 1).clamp(0, 999999);
    final newUnread = wasUnread
        ? (current.unreadCount - 1).clamp(0, 999999)
        : current.unreadCount;

    state = AsyncData(
      current.copyWith(
        items: updatedList,
        total: newTotal,
        unreadCount: newUnread,
      ),
    );
    if (wasUnread) {
      ref.read(unreadCountProvider.notifier).decrement(1);
    }

    try {
      await ref
          .read(apiClientProvider)
          .delete<dynamic>(NotificationConstants.deletePath(id));
    } catch (e) {
      state = AsyncData(current);
      if (wasUnread) {
        ref.read(unreadCountProvider.notifier).setCount(current.unreadCount);
      }
      rethrow;
    }
  }

  void undoDelete(NotificationItem item, int index) {
    final current = state.value;
    if (current == null) return;

    final restoredList = [...current.items];
    if (index >= 0 && index <= restoredList.length) {
      restoredList.insert(index, item);
    } else {
      restoredList.add(item);
    }
    final newUnread = !item.isRead
        ? current.unreadCount + 1
        : current.unreadCount;
    state = AsyncData(
      current.copyWith(
        items: restoredList,
        total: current.total + 1,
        unreadCount: newUnread,
      ),
    );
    if (!item.isRead) {
      ref.read(unreadCountProvider.notifier).setCount(newUnread);
    }
  }

  Future<void> deleteAllNotifications() async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(items: const [], total: 0, unreadCount: 0),
    );
    ref.read(unreadCountProvider.notifier).clear();

    try {
      await ref
          .read(apiClientProvider)
          .delete<dynamic>(NotificationConstants.deleteAllPath);
    } catch (e) {
      state = AsyncData(current);
      ref.read(unreadCountProvider.notifier).setCount(current.unreadCount);
      rethrow;
    }
  }
}

final notificationsFeedProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationsFeedNotifier,
      NotificationsFeedState
    >(NotificationsFeedNotifier.new);
