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
  static const String resetPassword = '/reset-password';

  static const String jobs = '/jobs';
  static const String myApplications = '/my-applications';
  static const String certificates = '/certificates';
  static const String profile = '/profile';

  static String jobDetail(String jobId) => '/jobs/$jobId';
  static String applicationDetail(String applicationId) =>
      '/my-applications/$applicationId';
}
