import 'package:easy_localization/easy_localization.dart';

import 'jobs_constants.dart';
import 'jobs_models.dart';

/// Wording of a job for people: salary, how long ago it was posted, labels.
class JobFormat {
  const JobFormat._();

  /// i18next-style count key (`<key>_one` / `<key>_other`) shared with the web
  /// locale files; easy_localization's plural() expects nested keys instead.
  static String countText(String key, int count) => tr(
    '${key}_${count == 1 ? 'one' : 'other'}',
    namedArgs: {'count': '$count'},
  );

  /// "25–35M VND", "From 20M VND", "Up to 30M VND"; null when the salary is
  /// negotiable or missing.
  static String? salaryAmount(JobPosting job) {
    if (!job.hasSalary) return null;
    final min = (job.salaryMin ?? 0) > 0 ? job.salaryMin! : null;
    final max = (job.salaryMax ?? 0) > 0 ? job.salaryMax! : null;
    final vnd = job.currency == JobConstants.currencyVnd;
    String number(num value) =>
        vnd ? _trimZero(value / JobConstants.vndPerMillion) : _grouped(value);
    final unit = vnd ? 'M ${job.currency}' : ' ${job.currency}';
    if (min != null && max != null) {
      return min == max
          ? '${number(min)}$unit'
          : '${number(min)}–${number(max)}$unit';
    }
    if (min != null) {
      return tr(
        'jobs.salary.from',
        namedArgs: {'amount': '${number(min)}$unit'},
      );
    }
    return tr(
      'jobs.salary.upTo',
      namedArgs: {'amount': '${number(max!)}$unit'},
    );
  }

  /// "25" for 25.0 and "7.5" for 7.5.
  static String _trimZero(num value) {
    final text = value.toStringAsFixed(1);
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }

  /// "1,500" for 1500.
  static String _grouped(num value) => value
      .round()
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  /// "today", "3 days ago", "1 week ago", "2 months ago".
  static String? postedAgo(DateTime? createdAt, DateTime now) {
    if (createdAt == null) return null;
    final days = now.difference(createdAt).inDays;
    if (days <= 0) return tr('jobs.ago.today');
    if (days < JobConstants.daysPerWeek) {
      return countText('jobs.ago.days', days);
    }
    if (days < JobConstants.daysPerMonth) {
      return countText('jobs.ago.weeks', days ~/ JobConstants.daysPerWeek);
    }
    return countText('jobs.ago.months', days ~/ JobConstants.daysPerMonth);
  }

  /// Short calendar date as in the design ("25 Oct"), in the device time zone.
  /// A date in another year, or more than about six months from [now], also
  /// shows its year ("11 Apr 2027"), so a deadline is never ambiguous.
  static String shortDate(DateTime value, String locale, DateTime now) {
    final local = value.toLocal();
    final today = now.toLocal();
    final showYear =
        local.year != today.year ||
        local.difference(today).inDays.abs() > JobConstants.yearShownAfterDays;
    return DateFormat(showYear ? 'd MMM y' : 'd MMM', locale).format(local);
  }

  /// "Apply by 25 Oct"; null when the job has no deadline.
  static String? applyBy(DateTime? expiresAt, String locale, DateTime now) =>
      expiresAt == null
      ? null
      : tr(
          'home.latest.applyBy',
          namedArgs: {'date': shortDate(expiresAt, locale, now)},
        );

  static String employmentLabel(String value) =>
      JobConstants.employmentTypes.contains(value)
      ? tr(JobConstants.employmentKey(value))
      : value;

  static String levelLabel(String value) =>
      JobConstants.levels.contains(value.toLowerCase())
      ? tr(JobConstants.levelKey(value))
      : value;
}
