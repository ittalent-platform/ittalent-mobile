import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/painting.dart';

import '../../../components/ui/app_badge.dart';
import '../../../theme/app_colors.dart';

class ApplicationConstants {
  const ApplicationConstants._();

  static const String statusSubmitted = 'submitted';
  static const String statusUnderReview = 'under_review';
  static const String statusInterviewing = 'interviewing';
  static const String statusOffered = 'offered';
  static const String statusHired = 'hired';
  static const String statusRejected = 'rejected';
  static const String statusWithdrawn = 'withdrawn';
  static const String statusPositionFilled = 'position_filled';

  static const List<String> statuses = [
    statusSubmitted,
    statusUnderReview,
    statusInterviewing,
    statusOffered,
    statusHired,
    statusRejected,
    statusWithdrawn,
    statusPositionFilled,
  ];

  /// The forward path shown as "Step n of 5"; other statuses end the process.
  static const List<String> progressSteps = [
    statusSubmitted,
    statusUnderReview,
    statusInterviewing,
    statusOffered,
    statusHired,
  ];

  /// Short reference shown to people, as on the web ("APP-9011").
  static String displayId(String id) =>
      'APP-${(id.length > 4 ? id.substring(id.length - 4) : id).toUpperCase()}';

  /// "Submitted" presets of the filter sheet, keyed like `applications.range.*`.
  static const String within7Days = '7d';
  static const String within30Days = '30d';
  static const String within3Months = '3m';
  static const List<String> submittedPresets = [
    within7Days,
    within30Days,
    within3Months,
  ];

  /// First day included by a "Submitted" preset, counted back from [now].
  static DateTime presetStart(String preset, DateTime now) {
    switch (preset) {
      case within7Days:
        return DateTime(now.year, now.month, now.day - 7);
      case within30Days:
        return DateTime(now.year, now.month, now.day - 30);
      default:
        return DateTime(now.year, now.month - 3, now.day);
    }
  }

  /// The preset whose start equals [from] today, if any.
  static String? presetOf(DateTime? from, DateTime now) {
    if (from == null) return null;
    for (final preset in submittedPresets) {
      if (presetStart(preset, now) == from) return preset;
    }
    return null;
  }

  /// i18next-style count key (`<key>_one` / `<key>_other`) shared with the web
  /// locale files; easy_localization's plural() expects nested keys instead.
  static String countText(String key, int count) => tr(
    '${key}_${count == 1 ? 'one' : 'other'}',
    namedArgs: {'count': '$count'},
  );

  /// Short calendar date as in the design ("28 Sep"), in the device time zone.
  static String shortDate(DateTime value, String locale) =>
      DateFormat('d MMM', locale).format(value.toLocal());

  /// Date and time as in the design ("10 Sep 2026, 14:00").
  static String dateTime(DateTime value, String locale) =>
      DateFormat('d MMM y, HH:mm', locale).format(value.toLocal());

  static const String sortSubmittedAt = 'submittedAt';
  static const String orderDescending = 'desc';
  static const String orderAscending = 'asc';

  static const String listPath = '/api/v1/me/applications';
  static String detailPath(String id) => '$listPath/$id';
  static String historyPath(String id) => '$listPath/$id/history';
  static const int historyPageSize = 100;
  static const int pageSize = 20;
  static const int searchMaxLength = 100;
  static const Duration searchDebounce = Duration(milliseconds: 400);
  static const double loadMoreThreshold = 240;

  /// Calendar day (YYYY-MM-DD) of a timestamp, in the device's time zone.
  static String day(DateTime value) =>
      value.toLocal().toIso8601String().substring(0, 10);

  static BadgeTone badgeToneForStatus(String status) {
    switch (status) {
      case statusSubmitted:
        return BadgeTone.neutral;
      case statusUnderReview:
        return BadgeTone.info;
      case statusInterviewing:
        return BadgeTone.blocked;
      case statusOffered:
        return BadgeTone.warning;
      case statusHired:
        return BadgeTone.success;
      case statusRejected:
        return BadgeTone.error;
      default:
        return BadgeTone.neutral;
    }
  }

  /// Translation key of the status word; unknown statuses fall back to the raw value.
  static String statusKey(String status) =>
      statuses.contains(status) ? 'applications.status.$status' : status;

  /// Solid colour of a status (timeline dots, progress), from its badge tone.
  static Color toneColor(String status, AppColors colors) {
    switch (badgeToneForStatus(status)) {
      case BadgeTone.success:
        return colors.statusSuccessFg;
      case BadgeTone.warning:
        return colors.statusWarningFg;
      case BadgeTone.info:
        return colors.statusInfoFg;
      case BadgeTone.blocked:
        return colors.statusBlockedFg;
      case BadgeTone.error:
        return colors.statusErrorFg;
      case BadgeTone.peach:
        return colors.statusPeachFg;
      case BadgeTone.neutral:
        return colors.statusNeutralFg;
    }
  }
}
