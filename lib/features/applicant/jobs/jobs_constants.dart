/// Values shared by the public job list, its search and filters, and the detail.
class JobConstants {
  const JobConstants._();

  static const String listPath = '/api/v1/job-postings';
  static String detailPath(String id) => '$listPath/$id/public';

  /// The API serves at most 100 jobs a page. Every page is read once, so that
  /// the counts, search and filters work on the whole market as on the web.
  static const int fetchPageSize = 100;

  /// A posting younger than this many days wears the "New" badge.
  static const int newBadgeDays = 5;

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
