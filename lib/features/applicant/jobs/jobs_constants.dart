/// Values shared by the public job list, its search and filters, and the detail.
class JobConstants {
  const JobConstants._();

  static const String listPath = '/api/v1/job-postings';
  static String detailPath(String id) => '$listPath/$id/public';

  /// The job's page on the web, which "Share" copies.
  static String sharePath(String id) => '/career/$id';

  /// The company shown under a job comes from the public company page.
  static String companyPath(String id) => '/api/v1/enterprises/$id/public';

  /// The applicant's own applications; asked for one job to know whether the
  /// signed-in applicant already applied to it.
  static const String applicationsPath = '/api/v1/me/applications';

  /// The applicant's saved jobs: `POST` saves one (`{jobId}`), and
  /// `GET`/`DELETE` on `/jobs/:id` tell whether it is saved and take it out.
  static const String wishlistPath = '/api/v1/me/wishlist';
  static String wishlistJobPath(String id) => '$wishlistPath/jobs/$id';

  /// The API serves at most 100 jobs a page. Every page is read once, so that
  /// the counts, search and filters work on the whole market as on the web.
  static const int fetchPageSize = 100;

  /// Pages are requested a few at a time, not all at once. There is no cap on
  /// their number: the list, its counts and its filters are complete or they
  /// fail, never silently short.
  static const int fetchConcurrency = 4;

  /// A posting younger than this many days wears the "New" badge.
  static const int newBadgeDays = 5;

  /// A deadline further ahead than this (or in another year) shows its year.
  static const int yearShownAfterDays = 180;

  /// A keyword is 1–100 characters of letters (Vietnamese included), digits,
  /// spaces and `- . '`, as on the web.
  static const int searchMaxLength = 100;
  static final RegExp searchPattern = RegExp(r"^[a-zA-Z0-9\s.\-'À-ɏẠ-ỹ]*$");
  static const int suggestionLimit = 5;
  static const int recentSearchLimit = 5;

  /// Keywords offered under "Popular skills" of the search page. They are
  /// searched like any typed keyword.
  static const List<String> popularKeywords = [
    'React',
    'Java',
    'DevOps',
    'QA Automation',
    'Data Engineer',
    'Flutter',
    'Go',
  ];

  /// The quick filters of the chip row, next to "Filters": a city (matched
  /// inside the job's location, so "Ho Chi Minh" also finds "Ho Chi Minh
  /// City"), the "Remote" job type, the "Senior" level and a minimum salary.
  static const String cityHoChiMinh = 'Ho Chi Minh';
  static const String quickLevel = 'senior';
  static const int quickSalaryMin = 20;

  /// The salary filter is typed in millions of VND a month, a few digits.
  static const int salaryDigits = 5;

  static const int daysPerWeek = 7;
  static const int daysPerMonth = 30;

  /// The job text shows this many lines before "Read more".
  static const int aboutCollapsedLines = 4;

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
