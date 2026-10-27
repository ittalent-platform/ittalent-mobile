import 'package:dio/dio.dart';
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

  group('NotificationsScreen', () {
    late FakeAdapter adapter;

    setUp(() {
      adapter = FakeAdapter((options) {
        if (options.path == NotificationConstants.unreadCountPath) {
          return jsonBody({'unreadCount': 2});
        }
        if (options.path == NotificationConstants.listPath) {
          final isRead = options.queryParameters['isRead'];
          final type = options.queryParameters['type'];

          if (isRead == false) {
            // Unread tab
            return jsonBody({
              'items': [
                _mockItem(
                  id: 'notif-1',
                  title: 'Interview scheduled',
                  message: 'PM at CloudBridge',
                  type: NotificationConstants.typeInterviewScheduled,
                  isRead: false,
                  createdAt: '2026-10-27T08:00:00.000Z',
                ),
                _mockItem(
                  id: 'notif-2',
                  title: 'Scheduled maintenance',
                  message: 'Server upgrades',
                  type: NotificationConstants.typeSystemAnnouncement,
                  isRead: false,
                  createdAt: '2026-10-27T06:00:00.000Z',
                ),
              ],
              'total': 2,
              'unreadCount': 2,
              'page': 1,
              'limit': 10,
              'totalPages': 1,
            });
          }

          if (type == NotificationConstants.typeSystemAnnouncement) {
            // Announcements tab
            return jsonBody({
              'items': [
                _mockItem(
                  id: 'notif-2',
                  title: 'Scheduled maintenance',
                  message: 'Server upgrades',
                  type: NotificationConstants.typeSystemAnnouncement,
                  isRead: false,
                  createdAt: '2026-10-27T06:00:00.000Z',
                ),
              ],
              'total': 1,
              'unreadCount': 1,
              'page': 1,
              'limit': 10,
              'totalPages': 1,
            });
          }

          // All tab
          return jsonBody({
            'items': [
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
              _mockItem(
                id: 'notif-3',
                title: 'Application status changed',
                message: 'DevOps at Pixel Labs moved to Offered',
                type: NotificationConstants.typeApplicationStatusChanged,
                isRead: true,
                createdAt: DateTime.now()
                    .subtract(const Duration(days: 1))
                    .toIso8601String(),
              ),
              _mockItem(
                id: 'notif-4',
                title: 'Application submitted',
                message: 'Nova Fintech',
                type: NotificationConstants.typeApplicationSubmitted,
                isRead: true,
                createdAt: DateTime.now()
                    .subtract(const Duration(days: 5))
                    .toIso8601String(),
              ),
            ],
            'total': 4,
            'unreadCount': 2,
            'page': 1,
            'limit': 10,
            'totalPages': 1,
          });
        }
        return ResponseBody.fromString('Not found', 404);
      });
    });

    testWidgets('renders header, tabs, and grouped list items', (tester) async {
      await pumpWithApi(
        tester,
        adapter,
        const NotificationsScreen(),
        size: const Size(600, 1000),
      );

      // Header checks
      expect(find.text('notifications.title'), findsOneWidget);
      expect(find.text('notifications.unreadCount'), findsOneWidget);

      // Tab checks
      expect(find.text('notifications.tabs.all'), findsOneWidget);
      expect(find.text('notifications.tabs.unread'), findsOneWidget);
      expect(find.text('notifications.tabs.announcements'), findsOneWidget);

      // Group headers
      expect(find.text('notifications.groups.today'), findsOneWidget);
      expect(find.text('notifications.groups.yesterday'), findsOneWidget);
      expect(find.text('notifications.groups.earlier'), findsOneWidget);

      // Notification titles
      expect(find.text('Interview scheduled'), findsOneWidget);
      expect(find.text('Scheduled maintenance'), findsOneWidget);
      expect(find.text('Application status changed'), findsOneWidget);
      expect(find.text('Application submitted'), findsOneWidget);

      // Announcement tag
      expect(find.text('notifications.announcement.from'), findsOneWidget);

      // Footer showing count
      expect(find.text('notifications.showingCount'), findsOneWidget);
    });

    testWidgets('switching to Announcements tab filters only announcements', (
      tester,
    ) async {
      await pumpWithApi(
        tester,
        adapter,
        const NotificationsScreen(),
        size: const Size(600, 1000),
      );

      // Tap Announcements tab
      final announcementsTab = find.byKey(
        const Key('notification_tab_announcements'),
      );
      await tester.ensureVisible(announcementsTab);
      await tester.tap(announcementsTab);
      await tester.pumpAndSettle();

      expect(find.text('Scheduled maintenance'), findsOneWidget);
      expect(find.text('Interview scheduled'), findsNothing);
      expect(
        find.text('notifications.announcement.allAnnouncementsSeen'),
        findsOneWidget,
      );
    });

    testWidgets('shows empty state when tab has no notifications', (
      tester,
    ) async {
      final emptyAdapter = FakeAdapter((options) {
        if (options.path == NotificationConstants.unreadCountPath) {
          return jsonBody({'unreadCount': 0});
        }
        return jsonBody({
          'items': <Map<String, dynamic>>[],
          'total': 0,
          'unreadCount': 0,
          'page': 1,
          'limit': 10,
          'totalPages': 0,
        });
      });

      await pumpWithApi(
        tester,
        emptyAdapter,
        const NotificationsScreen(),
        size: const Size(600, 1000),
      );

      expect(find.text('notifications.empty.noNotifications'), findsOneWidget);
      expect(find.text('notifications.actions.browseJobs'), findsOneWidget);
    });

    testWidgets('shows error state and can retry on failure', (tester) async {
      var failed = true;
      final errorAdapter = FakeAdapter((options) {
        if (failed) {
          return ResponseBody.fromString('Internal error', 500);
        }
        return jsonBody({
          'items': [
            _mockItem(
              id: 'notif-1',
              title: 'Success after retry',
              message: 'Retry succeeded',
              type: NotificationConstants.typeAccountAlert,
              isRead: true,
              createdAt: DateTime.now().toIso8601String(),
            ),
          ],
          'total': 1,
          'unreadCount': 0,
          'page': 1,
          'limit': 10,
          'totalPages': 1,
        });
      });

      await pumpWithApi(
        tester,
        errorAdapter,
        const NotificationsScreen(),
        size: const Size(600, 1000),
      );

      expect(find.text('notifications.error.loadTitle'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      failed = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Success after retry'), findsOneWidget);
    });
  });
}
