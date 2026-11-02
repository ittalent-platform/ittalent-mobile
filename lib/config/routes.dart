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

  static String companyDetail(String companyId) => '/companies/$companyId';
  static String applicationDetail(String applicationId) =>
      '/my-applications/$applicationId';
  static String applicationHistory(String applicationId) =>
      '/my-applications/$applicationId/history';
  static String announcementDetail(String id) =>
      '/notifications/announcements/$id';
}
