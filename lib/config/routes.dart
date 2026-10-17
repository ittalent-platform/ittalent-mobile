class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String jobs = '/jobs';
  static const String myApplications = '/my-applications';
  static const String certificates = '/certificates';
  static const String profile = '/profile';
  static const String login = '/auth/login';

  static String jobDetail(String jobId) => '/jobs/$jobId';
  static String applicationDetail(String applicationId) =>
      '/my-applications/$applicationId';
}
