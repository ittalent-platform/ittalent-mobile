/// The three tabs of a company page.
enum CompanyTab { about, jobs, benefits }

/// What a filter sheet lets the user pick.
enum CompanyFilterGroup { industry, size, city }

/// Values shared by the public company list, its search and filters, and the
/// company page (UC-BENT-01, UC-BENT-02, UC-BENT-03).
class CompanyConstants {
  const CompanyConstants._();

  static const String listPath = '/api/v1/enterprises/public';
  static const String industriesPath = '/api/v1/enterprises/public/industries';
  static String detailPath(String id) => '/api/v1/enterprises/$id/public';

  /// The open jobs of one company come from the public job list, asked for
  /// that company only.
  static const String jobsPath = '/api/v1/job-postings';

  static const int pageSize = 20;
  static const int jobsPageSize = 5;

  /// The API accepts a keyword of 1–100 characters.
  static const int searchMaxLength = 100;
  static const Duration searchDebounce = Duration(milliseconds: 400);
  static const double loadMoreThreshold = 240;

  /// `company_size` values of the API, smallest first.
  static const List<String> sizes = [
    '1-10',
    '11-50',
    '51-200',
    '201-500',
    '501-1000',
    '1000+',
  ];

  /// City choices, the same list the web uses for company cities. The API
  /// matches a city by name, so "Ho Chi Minh" also finds "Ho Chi Minh City".
  static const List<String> cities = [
    'Ho Chi Minh',
    'Ha Noi',
    'Da Nang',
    'Can Tho',
    'Hai Phong',
    'Binh Duong',
    'Dong Nai',
  ];

  /// A salary in VND is shown in millions ("45M VND").
  static const int vndPerMillion = 1000000;
  static const String currencyVnd = 'VND';

  /// A deadline further ahead than this (or in another year) shows its year.
  static const int yearShownAfterDays = 180;

  /// The API answers 404 for a company that is missing, suspended or removed,
  /// and 400 for an id that is not an id: both mean "not available".
  static const int statusBadRequest = 400;

  /// Heights and sizes of the company page, as in the design.
  static const double coverHeight = 130;
  static const double logoSize = 68;
  static const double logoBorder = 4;

  /// How far the logo reaches up into the cover.
  static const double logoOverlap = 32;
  static const double cardLogoSize = 48;
}
