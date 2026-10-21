import 'package:easy_localization/easy_localization.dart';

import '../../../components/ui/app_badge.dart';

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

  static const String sortSubmittedAt = 'submittedAt';
  static const String orderDescending = 'desc';
  static const String orderAscending = 'asc';

  static const String listPath = '/api/v1/me/applications';
  static const int pageSize = 20;
  static const int searchMaxLength = 100;
  static const Duration searchDebounce = Duration(milliseconds: 400);
  static const double loadMoreThreshold = 240;

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
}
