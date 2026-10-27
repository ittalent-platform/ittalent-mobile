import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/applicant/notifications/announcement_detail_screen.dart';
import 'package:ittalent_mobile/features/applicant/notifications/notifications_constants.dart';
import 'package:ittalent_mobile/features/applicant/notifications/notifications_providers.dart';

import '../../helpers/fake_api.dart';

void main() {
  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
  });

  group('AnnouncementDetailScreen', () {
    late FakeAdapter adapter;
    late NotificationItem announcement;

    setUp(() {
      announcement = NotificationItem(
        id: 'announce-1',
        title: 'Scheduled maintenance on 18 Oct',
        message: 'ITTalent will be unavailable from 22:00 to 23:30 while we upgrade our servers.',
        type: NotificationConstants.typeSystemAnnouncement,
        isRead: false,
        createdAt: DateTime(2026, 10, 11, 9, 40),
      );

      adapter = FakeAdapter((options) {
        if (options.path == NotificationConstants.deletePath('announce-1')) {
          if (options.method == 'GET') {
            return jsonBody(announcement.toJson());
          }
          if (options.method == 'DELETE') {
            return jsonBody({'success': true});
          }
        }
        if (options.path == NotificationConstants.readPath('announce-1')) {
          return jsonBody({'id': 'announce-1', 'isRead': true});
        }
        if (options.path == NotificationConstants.unreadCountPath) {
          return jsonBody({'unreadCount': 1});
        }
        return ResponseBody.fromString('Not found', 404);
      });
    });

    testWidgets('renders header, title, body, and non-reply notice banner', (
      tester,
    ) async {
      await pumpWithApi(
        tester,
        adapter,
        AnnouncementDetailScreen(id: 'announce-1', initialItem: announcement),
        size: const Size(600, 1000),
      );

      // Back button
      expect(find.byKey(const Key('announcement_back_btn')), findsOneWidget);
      expect(find.byKey(const Key('announcement_delete_btn')), findsOneWidget);

      // Sender and title
      expect(find.text('notifications.announcement.sender'), findsOneWidget);
      expect(find.text('Scheduled maintenance on 18 Oct'), findsOneWidget);

      // Body text
      expect(
        find.text(
          'ITTalent will be unavailable from 22:00 to 23:30 while we upgrade our servers.',
        ),
        findsOneWidget,
      );

      // Non-reply banner
      expect(
        find.text('notifications.announcement.repliesNotPossible'),
        findsOneWidget,
      );
    });

    testWidgets('marks unread announcement as read on open', (tester) async {
      await pumpWithApi(
        tester,
        adapter,
        AnnouncementDetailScreen(id: 'announce-1', initialItem: announcement),
        size: const Size(600, 1000),
      );

      expect(
        adapter.requests.any(
          (r) => r.path == NotificationConstants.readPath('announce-1'),
        ),
        isTrue,
      );
    });

    testWidgets('shows error state when announcement cannot be loaded', (
      tester,
    ) async {
      final errorAdapter = FakeAdapter((options) {
        if (options.path == NotificationConstants.unreadCountPath) {
          return jsonBody({'unreadCount': 0});
        }
        return ResponseBody.fromString('Server error', 500);
      });

      await pumpWithApi(
        tester,
        errorAdapter,
        const AnnouncementDetailScreen(id: 'missing-id'),
        size: const Size(600, 1000),
      );

      expect(find.text('notifications.error.unavailableTitle'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
