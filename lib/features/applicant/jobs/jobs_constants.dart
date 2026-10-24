/// Values shared by the public job list, its search and filters, and the detail.
class JobConstants {
  const JobConstants._();

  static const String listPath = '/api/v1/job-postings';
  static String detailPath(String id) => '$listPath/$id/public';

  /// The API serves at most 100 jobs a page. Every page is read once, so that
  /// the counts, search and filters work on the whole market as on the web.
  static const int fetchPageSize = 100;

  /// Pages are requested a few at a time, not all at once, and never beyond
  /// [maxPages] (2,000 jobs): a guard against an endless or runaway listing.
  static const int fetchConcurrency = 4;
  static const int maxPages = 20;

  /// A posting younger than this many days wears the "New" badge.
  static const int newBadgeDays = 5;

  /// A deadline further ahead than this (or in another year) shows its year.
  static const int yearShownAfterDays = 180;

  /// A keyword is 1–100 characters of letters (Vietnamese included), digits,
  /// spaces and `- . '`, as on the web.
  static const int searchMaxLength = 100;
  static final RegExp searchPattern = RegExp(
    r"^[a-zA-Z0-9\s.\-'\u00C0-\u024F\u1EA0-\u1EF9]*$",
  );
  static const int suggestionLimit = 5;
  static const int recentSearchLimit = 5;

  static const int daysPerWeek = 7;
  static const int daysPerMonth = 30;

  static const String currencyVnd = 'VND';
  static const int vndPerMillion = 1000000;

  static const String typeFullTime = 'Full-time';
  static const String typePartTime = 'Part-time';
  static const String typeContract = 'Contract';
  static const String typeInternship = 'Internship';
  static const String typeRemote = 'Remote';

  /// Employment types as the API stores them, in the order of the filter.
  static const List<String> employmentTypes = [
    typeFullTime,
    typePartTime,
    typeContract,
    typeInternship,
    typeRemote,
  ];

  /// Translation key of an employment type, shared with the web.
  static String employmentKey(String type) =>
      'jobPostings.employmentTypes.$type';

  /// Levels as recruiters pick them, lower-cased, in the order of the filter.
  static const List<String> levels = [
    'intern',
    'junior',
    'mid',
    'senior',
    'lead',
  ];

  static String levelKey(String level) => 'jobs.level.${level.toLowerCase()}';
}
