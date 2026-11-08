class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetLinkSent = '/reset-link-sent';
  static const String verifyEmail = '/verify-email';
  static const String verifyEmailNotice = '/verify-email-notice';
  static const String emailVerified = '/email-verified';
  static const String resetPassword = '/reset-password';

  static const String jobs = '/jobs';
  static const String companies = '/companies';
  static const String myApplications = '/my-applications';
  static const String notifications = '/notifications';
  static const String certificates = '/certificates';
  static const String documents = '/profile/documents';
  static const String savedJobs = '/profile/saved-jobs';
  static const String portfolio = '/portfolio';
  static const String profile = '/profile';
  static const String profileDetails = '/profile/details';
  static const String editProfile = '/profile/details/edit';
  static const String changePassword = '/profile/password';

  static String jobDetail(String jobId) => '/jobs/$jobId';
  static String jobApply(String jobId) => '/jobs/$jobId/apply';

  /// The apply flow needs an account: a guest is sent to sign in instead.
  static bool isJobApply(String location) {
    final segments = Uri.parse(location).pathSegments;
    return segments.length == 3 &&
        '/${segments[0]}' == jobs &&
        segments[2] == 'apply';
  }

  /// The query parameter of the login page that says where to go once signed
  /// in.
  static const String fromParam = 'from';

  /// The login page, which brings the applicant back to [location] after
  /// they sign in (a job they were reading, the apply page they were sent
  /// away from). Without a [location] it is the plain login page.
  static String loginThen(String? location) {
    final target = returnTarget(location);
    return target == null
        ? login
        : Uri(path: login, queryParameters: {fromParam: target}).toString();
  }

  /// [from] if it is a place a guest may have come from, else null. Only a
  /// job or a company page of this app qualifies: a `from` is read from a
  /// link, so a full address ("https://…", "//host"), an auth page (a loop)
  /// or any other page never passes.
  static String? returnTarget(String? from) {
    if (from == null || from.isEmpty || !from.startsWith('/')) return null;
    if (from.startsWith('//') || from.contains('\\')) return null;
    final uri = Uri.tryParse(from);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
    final segments = uri.pathSegments;
    if (segments.length < 2 || segments.any((segment) => segment.isEmpty)) {
      return null;
    }
    final area = '/${segments.first}';
    return area == jobs || area == companies ? from : null;
  }

  static String companyDetail(String companyId) => '/companies/$companyId';
  static String applicationDetail(String applicationId) =>
      '/my-applications/$applicationId';
  static String applicationHistory(String applicationId) =>
      '/my-applications/$applicationId/history';
  static String announcementDetail(String id) =>
      '/notifications/announcements/$id';
}
