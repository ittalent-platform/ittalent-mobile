import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/applicant/notifications/notifications_constants.dart';
import 'package:ittalent_mobile/features/applicant/notifications/notifications_screen.dart';

import '../../helpers/fake_api.dart';

Map<String, dynamic> _mockItem({
  required String id,
  required String title,
  required String message,
  required String type,
  bool isRead = false,
  required String createdAt,
}) => {
  'id': id,
  'title': title,
  'message': message,
  'type': type,
  'category': 'info',
  'isRead': isRead,
  'createdAt': createdAt,
};

void main() {
  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
  });

  group('Notifications Actions & Sheets', () {
    late FakeAdapter adapter;
    late List<Map<String, dynamic>> items;
    var unreadCount = 2;

    setUp(() {
      items = [
        _mockItem(
          id: 'notif-1',
          title: 'Interview scheduled',
          message: 'PM at CloudBridge',
          type: NotificationConstants.typeInterviewScheduled,
          isRead: false,
          createdAt: DateTime.now().toIso8601String(),
        ),
        _mockItem(
          id: 'notif-2',
          title: 'Scheduled maintenance',
          message: 'Server upgrades',
          type: NotificationConstants.typeSystemAnnouncement,
          isRead: false,
          createdAt: DateTime.now().toIso8601String(),
        ),
      ];
      unreadCount = 2;

      adapter = FakeAdapter((options) {
        if (options.path == NotificationConstants.unreadCountPath) {
          return jsonBody({'unreadCount': unreadCount});
        }
        if (options.path == NotificationConstants.listPath) {
          return jsonBody({
            'items': items,
            'total': items.length,
            'unreadCount': unreadCount,
            'page': 1,
            'limit': 10,
            'totalPages': 1,
          });
        }
        if (options.path == NotificationConstants.readPath('notif-1')) {
          unreadCount = 1;
          return jsonBody({'id': 'notif-1', 'isRead': true});
        }
        if (options.path == NotificationConstants.readAllPath) {
          unreadCount = 0;
          return jsonBody({'success': true});
        }
        if (options.path == NotificationConstants.deletePath('notif-1')) {
          items.removeWhere((e) => e['id'] == 'notif-1');
          unreadCount = 1;
          return jsonBody({'success': true});
        }
        if (options.path == NotificationConstants.deleteAllPath &&
            options.method == 'DELETE') {
          items.clear();
          unreadCount = 0;
          return jsonBody({'success': true});
        }
        return jsonBody({'success': true});
      });
    });

    testWidgets(
      'swiping tile left reveals action buttons; tapping Read marks read',
      (tester) async {
        await pumpWithApi(
          tester,
          adapter,
          const NotificationsScreen(),
          size: const Size(600, 1000),
        );

        final itemFinder = find.byKey(const Key('notification_item_notif-1'));
        expect(itemFinder, findsOneWidget);

        // Drag left to reveal actions
        await tester.drag(itemFinder, const Offset(-160, 0));
        await tester.pumpAndSettle();

        final readBtn = find.byKey(
          const Key('notification_swipe_read_notif-1'),
        );
        expect(readBtn, findsOneWidget);

        // Tap Read
        await tester.tap(readBtn);
        await tester.pumpAndSettle();

        expect(
          adapter.requests.any(
            (r) => r.path == NotificationConstants.readPath('notif-1'),
          ),
          isTrue,
        );
      },
    );

    testWidgets(
      'deleting a notification shows Undo snackbar and restores it on tap',
      (tester) async {
        await pumpWithApi(
          tester,
          adapter,
          const NotificationsScreen(),
          size: const Size(600, 1000),
        );

        final itemFinder = find.byKey(const Key('notification_item_notif-1'));
        await tester.drag(itemFinder, const Offset(-160, 0));
        await tester.pumpAndSettle();

        final deleteBtn = find.byKey(
          const Key('notification_swipe_delete_notif-1'),
        );
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        // Item should be removed from view
        expect(find.text('Interview scheduled'), findsNothing);

        // Floating snackbar is visible
        expect(find.text('notifications.toast.deleted'), findsOneWidget);
        expect(find.text('notifications.actions.undo'), findsOneWidget);

        // Tap Undo
        await tester.tap(find.text('notifications.actions.undo'));
        await tester.pumpAndSettle();

        // Item is restored
        expect(find.text('Interview scheduled'), findsOneWidget);
      },
    );

    testWidgets('long press opens NotificationActionSheet', (tester) async {
      await pumpWithApi(
        tester,
        adapter,
        const NotificationsScreen(),
        size: const Size(600, 1000),
      );

      final itemFinder = find.byKey(const Key('notification_item_notif-1'));
      await tester.longPress(itemFinder);
      await tester.pumpAndSettle();

      // Sheet opens
      expect(
        find.byKey(const Key('notification_action_toggle_read')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('notification_action_delete')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('notification_action_cancel')),
        findsOneWidget,
      );

      // Cancel closes sheet
      await tester.tap(find.byKey(const Key('notification_action_cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notification_action_cancel')), findsNothing);
    });

    testWidgets('more actions sheet allows Mark All as Read confirmation', (
      tester,
    ) async {
      await pumpWithApi(
        tester,
        adapter,
        const NotificationsScreen(),
        size: const Size(600, 1000),
      );

      // Tap top-right more actions button
      await tester.tap(find.byKey(const Key('notification_more_actions_btn')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('more_action_mark_all_read')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('more_action_delete_all')), findsOneWidget);

      // Tap Mark all as read
      await tester.tap(find.byKey(const Key('more_action_mark_all_read')));
      await tester.pumpAndSettle();

      // MarkAllReadSheet confirmation is shown
      expect(
        find.byKey(const Key('mark_all_read_confirm_btn')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('mark_all_read_cancel_btn')), findsOneWidget);

      // Confirm
      await tester.tap(find.byKey(const Key('mark_all_read_confirm_btn')));
      await tester.pumpAndSettle();

      expect(
        adapter.requests.any(
          (r) => r.path == NotificationConstants.readAllPath,
        ),
        isTrue,
      );
    });

    testWidgets('more actions sheet allows Delete All confirmation', (
      tester,
    ) async {
      await pumpWithApi(
        tester,
        adapter,
        const NotificationsScreen(),
        size: const Size(600, 1000),
      );

      await tester.tap(find.byKey(const Key('notification_more_actions_btn')));
      await tester.pumpAndSettle();

      // Tap Delete all
      await tester.tap(find.byKey(const Key('more_action_delete_all')));
      await tester.pumpAndSettle();

      // DeleteAllSheet confirmation is shown
      expect(find.byKey(const Key('delete_all_confirm_btn')), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.byKey(const Key('delete_all_confirm_btn')));
      await tester.pumpAndSettle();

      expect(
        adapter.requests.any(
          (r) =>
              r.path == NotificationConstants.deleteAllPath &&
              r.method == 'DELETE',
        ),
        isTrue,
      );
    });
  });
}
