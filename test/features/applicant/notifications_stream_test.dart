import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/applicant/notifications/notifications_constants.dart';
import 'package:ittalent_mobile/features/applicant/notifications/notifications_providers.dart';
import 'package:ittalent_mobile/features/applicant/notifications/notifications_stream_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationSseParser', () {
    test('parses SSE byte streams correctly ignoring heartbeat ping', () async {
      final controller = StreamController<List<int>>();

      final parsedEventsFuture = NotificationSseParser.parse(controller.stream)
          .toList();

      // Emit connected event
      controller.add(
        utf8.encode('event: connected\ndata: {"status":"connected"}\n\n'),
      );

      // Emit heartbeat ping (should be ignored by parser)
      controller.add(utf8.encode(': ping\n\n'));

      // Emit notification event
      controller.add(
        utf8.encode(
          'event: notification\ndata: {"id":"notif-sse-1","title":"New Interview","message":"PM at Tech Corp","type":"interview_scheduled","category":"info","isRead":false,"createdAt":"2026-11-05T00:00:00.000Z"}\n\n',
        ),
      );

      await controller.close();

      final events = await parsedEventsFuture;
      expect(events.length, 2);

      expect(events[0]['event'], 'connected');
      expect(events[0]['data']['status'], 'connected');

      expect(events[1]['event'], 'notification');
      expect(events[1]['data']['id'], 'notif-sse-1');
      expect(events[1]['data']['title'], 'New Interview');
    });

    test('handles multi-chunk line delivery', () async {
      final controller = StreamController<List<int>>();

      final parsedEventsFuture = NotificationSseParser.parse(controller.stream)
          .toList();

      // Send chunk split in middle of line
      controller.add(utf8.encode('event: notifi'));
      controller.add(utf8.encode('cation\ndata: {"id":"notif-split"}\n\n'));

      await controller.close();

      final events = await parsedEventsFuture;
      expect(events.length, 1);
      expect(events[0]['event'], 'notification');
      expect(events[0]['data']['id'], 'notif-split');
    });
  });

  group('NotificationsFeedNotifier.addLiveNotification', () {
    test('prepends new live notification and increases unread count', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(notificationsFeedProvider.notifier);

      // Manually seed state
      notifier.state = AsyncData(
        NotificationsFeedState(
          items: [
            NotificationItem(
              id: 'existing-1',
              title: 'Old notification',
              message: 'Old message',
              type: NotificationConstants.typeAccountAlert,
              isRead: true,
              createdAt: DateTime(2026, 10, 20),
            ),
          ],
          page: 1,
          totalPages: 1,
          total: 1,
          unreadCount: 0,
        ),
      );

      final newItem = NotificationItem(
        id: 'new-live-1',
        title: 'Application Passed',
        message: 'Congratulations',
        type: NotificationConstants.typeApplicationStatusChanged,
        isRead: false,
        createdAt: DateTime.now(),
      );

      notifier.addLiveNotification(newItem);

      final updatedState = container
          .read(notificationsFeedProvider)
          .asData
          ?.value;
      expect(updatedState, isNotNull);
      expect(updatedState!.items.length, 2);
      expect(updatedState.items.first.id, 'new-live-1');
      expect(updatedState.total, 2);
      expect(updatedState.unreadCount, 1);

      // Duplicate should be ignored
      notifier.addLiveNotification(newItem);
      expect(
        container.read(notificationsFeedProvider).asData?.value.items.length,
        2,
      );
    });
  });
}
