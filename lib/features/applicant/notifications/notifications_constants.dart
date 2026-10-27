import 'package:easy_localization/easy_localization.dart';

class NotificationConstants {
  const NotificationConstants._();

  static const String typeApplicationSubmitted = 'application_submitted';
  static const String typeApplicationStatusChanged =
      'application_status_changed';
  static const String typeInterviewScheduled = 'interview_scheduled';
  static const String typeInterviewRescheduled = 'interview_rescheduled';
  static const String typeInterviewCancelled = 'interview_cancelled';
  static const String typeSystemAnnouncement = 'system_announcement';
  static const String typeEnterpriseStatusChanged = 'enterprise_status_changed';
  static const String typeAccountAlert = 'account_alert';

  static const String tabAll = 'all';
  static const String tabUnread = 'unread';
  static const String tabAnnouncements = 'announcements';

  static const String groupToday = 'today';
  static const String groupYesterday = 'yesterday';
  static const String groupEarlier = 'earlier';
  static const String groupThisMonth = 'this_month';

  static const String listPath = '/api/v1/notifications';
  static const String unreadCountPath = '/api/v1/notifications/unread-count';
  static String readPath(String id) => '/api/v1/notifications/$id/read';
  static const String readAllPath = '/api/v1/notifications/read-all';
  static String deletePath(String id) => '/api/v1/notifications/$id';
  static const String deleteAllPath = '/api/v1/notifications';

  static const int pageSize = 10;
  static const int undoDurationSeconds = 5;

  /// Returns the section grouping key for [date] relative to [now].
  static String groupForDate(
    DateTime date, {
    DateTime? now,
    bool isAnnouncementsTab = false,
  }) {
    final current = now ?? DateTime.now();
    final localDate = date.toLocal();
    final localNow = current.toLocal();

    if (isAnnouncementsTab) {
      if (localDate.year == localNow.year &&
          localDate.month == localNow.month) {
        return groupThisMonth;
      }
      return groupEarlier;
    }

    final todayStart = DateTime(localNow.year, localNow.month, localNow.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    if (localDate.isAfter(todayStart) ||
        localDate.isAtSameMomentAs(todayStart)) {
      return groupToday;
    } else if (localDate.isAfter(yesterdayStart) ||
        localDate.isAtSameMomentAs(yesterdayStart)) {
      return groupYesterday;
    } else {
      return groupEarlier;
    }
  }

  /// Formats relative time according to the design specification:
  /// - < 1 min: "Just now"
  /// - < 60 min: "12 min ago"
  /// - same day: "2 h ago"
  /// - yesterday: "16:40"
  /// - earlier this year: "24 Sep"
  /// - previous years: "24 Sep 2025"
  static String formatRelativeTime(
    DateTime? date, {
    DateTime? now,
    String? locale,
  }) {
    if (date == null) return '—';
    final current = now ?? DateTime.now();
    final localDate = date.toLocal();
    final localNow = current.toLocal();

    final diff = localNow.difference(localDate);
    final diffMinutes = diff.inMinutes;

    if (diffMinutes < 1) {
      return tr('notifications.relativeTime.justNow');
    }

    if (diffMinutes < 60) {
      return tr(
        'notifications.relativeTime.minAgo',
        namedArgs: {'count': '$diffMinutes'},
      );
    }

    final todayStart = DateTime(localNow.year, localNow.month, localNow.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    if (localDate.isAfter(todayStart) ||
        localDate.isAtSameMomentAs(todayStart)) {
      final hours = diff.inHours;
      return tr(
        'notifications.relativeTime.hAgo',
        namedArgs: {'count': '$hours'},
      );
    }

    if (localDate.isAfter(yesterdayStart) ||
        localDate.isAtSameMomentAs(yesterdayStart)) {
      if (locale == null || locale == 'en') {
        return DateFormat('HH:mm').format(localDate);
      }
      return DateFormat('HH:mm', locale).format(localDate);
    }

    if (localDate.year == localNow.year) {
      if (locale == null || locale == 'en') {
        return DateFormat('d MMM').format(localDate);
      }
      return DateFormat('d MMM', locale).format(localDate);
    }

    if (locale == null || locale == 'en') {
      return DateFormat('d MMM y').format(localDate);
    }
    return DateFormat('d MMM y', locale).format(localDate);
  }

  /// Formats full announcement date time: e.g. "Sun 11 Oct 2026, 09:40"
  static String formatAnnouncementDateTime(DateTime? date, {String? locale}) {
    if (date == null) return '—';
    if (locale == null || locale == 'en') {
      return DateFormat('EEE d MMM y, HH:mm').format(date.toLocal());
    }
    return DateFormat('EEE d MMM y, HH:mm', locale).format(date.toLocal());
  }
}
