import 'package:easy_localization/easy_localization.dart';

import 'companies_constants.dart';
import 'companies_models.dart';

/// Wording of a company and its jobs for people.
class CompanyFormat {
  const CompanyFormat._();

  /// i18next-style count key (`<key>_one` / `<key>_other`) shared with the web
  /// locale files; easy_localization's plural() expects nested keys instead.
  static String countText(String key, int count) => tr(
    '${key}_${count == 1 ? 'one' : 'other'}',
    namedArgs: {'count': '$count'},
  );

  /// "51–200" for "51-200"; "1000+" stays as it is.
  static String sizeRange(String size) => size.replaceAll('-', '–');

  /// "51–200 people".
  static String sizeText(String size) =>
      tr('home.companies.size', namedArgs: {'size': sizeRange(size)});

  /// "Fintech · 51–200 people"; a part the company does not have is left out.
  static String subtitle(CompanySummary company) => [
    if (company.industry != null) company.industry!,
    if (company.companySize != null) sizeText(company.companySize!),
  ].join(' · ');

  /// "Fintech · 51–200 people · Ha Noi": the line under the name on the
  /// company page.
  static String pageSubtitle(CompanyDetail company) => [
    if (company.summary.industry != null) company.summary.industry!,
    if (company.summary.companySize != null)
      sizeText(company.summary.companySize!),
    if (company.headquarters != null) company.headquarters!,
  ].join(' · ');

  /// "Ha Noi, Ho Chi Minh City".
  static String cities(List<String> cities) => cities.join(', ');

  /// "8 open jobs", or "No open jobs" for none.
  static String openJobs(int count) => count > 0
      ? countText('companies.card.openJobs', count)
      : tr('companies.card.noOpenJobs');

  /// "45–60M VND", "From 20M VND", "Up to 30M VND"; null when the salary is
  /// negotiable or missing.
  static String? salaryAmount(CompanyJob job) {
    if (!job.hasSalary) return null;
    final min = (job.salaryMin ?? 0) > 0 ? job.salaryMin! : null;
    final max = (job.salaryMax ?? 0) > 0 ? job.salaryMax! : null;
    final vnd = job.currency == CompanyConstants.currencyVnd;
    String number(num value) => vnd
        ? _trimZero(value / CompanyConstants.vndPerMillion)
        : _grouped(value);
    final unit = vnd ? 'M ${job.currency}' : ' ${job.currency}';
    if (min != null && max != null) {
      return min == max
          ? '${number(min)}$unit'
          : '${number(min)}–${number(max)}$unit';
    }
    if (min != null) {
      return tr(
        'companies.jobs.salaryFrom',
        namedArgs: {'amount': '${number(min)}$unit'},
      );
    }
    return tr(
      'companies.jobs.salaryUpTo',
      namedArgs: {'amount': '${number(max!)}$unit'},
    );
  }

  /// What the salary line of a job says: the amount, "Negotiable" for a job
  /// that is, or null for a job with neither.
  static String? salaryText(CompanyJob job) => job.salaryNegotiable
      ? tr('companies.jobs.negotiable')
      : salaryAmount(job);

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

  /// "Ha Noi · Senior"; null when the job has neither.
  static String? jobPlace(CompanyJob job) {
    final parts = [
      if (job.location != null) job.location!,
      if (job.level != null) job.level!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Short calendar date as in the design ("25 Oct"), in the device time zone.
  /// A date in another year, or more than about six months from [now], also
  /// shows its year ("11 Apr 2027"), so a deadline is never ambiguous.
  static String shortDate(DateTime value, String locale, DateTime now) {
    final local = value.toLocal();
    final today = now.toLocal();
    final showYear =
        local.year != today.year ||
        local.difference(today).inDays.abs() >
            CompanyConstants.yearShownAfterDays;
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

  /// The address of a company website, or null when it is not a plain web
  /// address (only http and https open, so a stray `javascript:` never does).
  /// A bare "nimbuspay.example" opens over https.
  static Uri? websiteUri(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri;
  }

  /// "nimbuspay.example" for "https://www.nimbuspay.example/about".
  static String websiteLabel(Uri uri) =>
      uri.host.replaceFirst(RegExp(r'^www\.'), '');
}
