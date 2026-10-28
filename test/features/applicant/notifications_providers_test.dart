import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/features/applicant/notifications/notifications_constants.dart';
import 'package:ittalent_mobile/features/applicant/notifications/notifications_providers.dart';

import '../../helpers/fake_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationConstants', () {
    final now = DateTime(2026, 10, 27, 14, 30);

    test('groupForDate groups into today, yesterday, earlier', () {
      final today = DateTime(2026, 10, 27, 8, 0);
      final yesterday = DateTime(2026, 10, 26, 20, 0);
      final earlier = DateTime(2026, 10, 20, 10, 0);

      expect(
        NotificationConstants.groupForDate(today, now: now),
        NotificationConstants.groupToday,
      );
      expect(
        NotificationConstants.groupForDate(yesterday, now: now),
        NotificationConstants.groupYesterday,
      );
      expect(
        NotificationConstants.groupForDate(earlier, now: now),
        NotificationConstants.groupEarlier,
      );
    });

    test('groupForDate handles announcements tab (this_month vs earlier)', () {
      final thisMonth = DateTime(2026, 10, 5, 12, 0);
      final lastMonth = DateTime(2026, 9, 28, 12, 0);

      expect(
        NotificationConstants.groupForDate(
          thisMonth,
          now: now,
          isAnnouncementsTab: true,
        ),
        NotificationConstants.groupThisMonth,
      );
      expect(
        NotificationConstants.groupForDate(
          lastMonth,
          now: now,
          isAnnouncementsTab: true,
        ),
        NotificationConstants.groupEarlier,
      );
    });

    test('formatAnnouncementDateTime formats correctly', () {
      final dt = DateTime(2026, 10, 11, 9, 40);
      final str = NotificationConstants.formatAnnouncementDateTime(
        dt,
        locale: 'en',
      );
      expect(str, contains('11 Oct 2026'));
      expect(str, contains('09:40'));
    });
  });

  group('NotificationItem & NotificationsPage models', () {
    test('NotificationItem.fromJson parses all fields', () {
      final json = {
        'id': 'notif-1',
        'title': 'Interview scheduled',
        'message': 'PM at CloudBridge',
        'type': 'interview_scheduled',
        'category': 'info',
        'actionUrl': '/my-applications/app-1',
        'data': {'companyId': 'comp-1'},
        'isRead': false,
        'createdAt': '2026-10-27T08:00:00.000Z',
      };
      final item = NotificationItem.fromJson(json);

      expect(item.id, 'notif-1');
      expect(item.title, 'Interview scheduled');
      expect(item.message, 'PM at CloudBridge');
      expect(item.type, NotificationConstants.typeInterviewScheduled);
      expect(item.actionUrl, '/my-applications/app-1');
      expect(item.isRead, isFalse);
      expect(item.data?['companyId'], 'comp-1');
    });

    test('NotificationsPage.fromJson parses page data', () {
      final json = {
        'items': [
          {
            'id': 'notif-1',
            'title': 'Title 1',
            'message': 'Msg 1',
            'type': 'system_announcement',
            'isRead': false,
            'createdAt': '2026-10-27T08:00:00.000Z',
          },
        ],
        'total': 1,
        'unreadCount': 1,
        'page': 1,
        'limit': 10,
        'totalPages': 1,
      };
      final page = NotificationsPage.fromJson(json);

      expect(page.items.length, 1);
      expect(page.total, 1);
      expect(page.unreadCount, 1);
      expect(page.items.first.title, 'Title 1');
    });
  });

  group('NotificationsFeedNotifier & unreadCountProvider', () {
    late FakeAdapter adapter;
    late ProviderContainer container;

    setUp(() {
      adapter = FakeAdapter((options) {
        if (options.path == NotificationConstants.unreadCountPath) {
          return jsonBody({'unreadCount': 3});
        }
        if (options.path == NotificationConstants.listPath) {
          final page = options.queryParameters['page'] as int? ?? 1;
          if (page == 1) {
            return jsonBody({
              'items': [
                {
                  'id': 'notif-1',
                  'title': 'Scheduled maintenance',
                  'message': 'Servers upgrade',
                  'type': 'system_announcement',
                  'isRead': false,
                  'createdAt': '2026-10-27T10:00:00.000Z',
                },
                {
                  'id': 'notif-2',
                  'title': 'Application status changed',
                  'message': 'Offered',
                  'type': 'application_status_changed',
                  'isRead': true,
                  'createdAt': '2026-10-26T16:00:00.000Z',
                },
              ],
              'total': 3,
              'unreadCount': 1,
              'page': 1,
              'limit': 2,
              'totalPages': 2,
            });
          } else {
            return jsonBody({
              'items': [
                {
                  'id': 'notif-3',
                  'title': 'Application submitted',
                  'message': 'Nova Fintech',
                  'type': 'application_submitted',
                  'isRead': true,
                  'createdAt': '2026-10-20T10:00:00.000Z',
                },
              ],
              'total': 3,
              'unreadCount': 1,
              'page': 2,
              'limit': 2,
              'totalPages': 2,
            });
          }
        }
        if (options.path.startsWith('/api/v1/notifications/') &&
            options.path.endsWith('/read') &&
            options.method == 'PATCH') {
          return jsonBody({'success': true});
        }
        if (options.path == NotificationConstants.readAllPath &&
            options.method == 'PATCH') {
          return jsonBody({
            'updatedCount': 1,
            'unreadCount': 0,
            'message': 'All notifications marked as read',
          });
        }
        if (options.path.startsWith('/api/v1/notifications/') &&
            options.method == 'DELETE') {
          return jsonBody({'success': true, 'message': 'Deleted'});
        }
        if (options.path == NotificationConstants.deleteAllPath &&
            options.method == 'DELETE') {
          return jsonBody({'deletedCount': 3, 'message': 'All deleted'});
        }
        return ResponseBody.fromString('Not found', 404);
      });

      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..httpClientAdapter = adapter;
      container = ProviderContainer(
        overrides: [dioProvider.overrideWithValue(dio)],
      );
      final sub = container.listen(notificationsFeedProvider, (_, _) {});
      addTearDown(sub.close);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial load fetches first page and sets unreadCount', () async {
      final initial = await container.read(notificationsFeedProvider.future);

      expect(initial.items.length, 2);
      expect(initial.total, 3);
      expect(initial.hasMore, isTrue);
      expect(initial.unreadCount, 1);
      expect(container.read(unreadCountProvider), 1);
    });

    test('loadMore loads next page', () async {
      await container.read(notificationsFeedProvider.future);
      final notifier = container.read(notificationsFeedProvider.notifier);
      await notifier.loadMore();

      final state = container.read(notificationsFeedProvider).value!;
      expect(state.items.length, 3);
      expect(state.page, 2);
      expect(state.hasMore, isFalse);
    });

    test(
      'markAsRead updates item optimistically and decrements unreadCount',
      () async {
        await container.read(notificationsFeedProvider.future);
        final notifier = container.read(notificationsFeedProvider.notifier);

        await notifier.markAsRead('notif-1');

        final state = container.read(notificationsFeedProvider).value!;
        expect(state.items.first.isRead, isTrue);
        expect(state.unreadCount, 0);
        expect(container.read(unreadCountProvider), 0);
      },
    );

    test(
      'deleteNotification removes item and undoDelete restores it',
      () async {
        await container.read(notificationsFeedProvider.future);
        final notifier = container.read(notificationsFeedProvider.notifier);

        final deletedItem = container
            .read(notificationsFeedProvider)
            .value!
            .items
            .first;

        await notifier.deleteNotification('notif-1');

        var state = container.read(notificationsFeedProvider).value!;
        expect(state.items.length, 1);
        expect(state.total, 2);
        expect(state.unreadCount, 0);

        // Undo deletion
        notifier.undoDelete(deletedItem, 0);
        state = container.read(notificationsFeedProvider).value!;
        expect(state.items.length, 2);
        expect(state.total, 3);
        expect(state.unreadCount, 1);
        expect(container.read(unreadCountProvider), 1);
      },
    );

    test('markAllAsRead marks all read and clears unread count', () async {
      await container.read(notificationsFeedProvider.future);
      final notifier = container.read(notificationsFeedProvider.notifier);

      await notifier.markAllAsRead();

      final state = container.read(notificationsFeedProvider).value!;
      expect(state.items.every((i) => i.isRead), isTrue);
      expect(state.unreadCount, 0);
      expect(container.read(unreadCountProvider), 0);
    });

    test('deleteAllNotifications clears all items', () async {
      await container.read(notificationsFeedProvider.future);
      final notifier = container.read(notificationsFeedProvider.notifier);

      await notifier.deleteAllNotifications();

      final state = container.read(notificationsFeedProvider).value!;
      expect(state.items, isEmpty);
      expect(state.total, 0);
      expect(state.unreadCount, 0);
      expect(container.read(unreadCountProvider), 0);
    });
  });
}
