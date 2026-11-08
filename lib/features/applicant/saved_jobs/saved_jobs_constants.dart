class SavedJobsConstants {
  const SavedJobsConstants._();

  static const String wishlistPath = '/api/v1/me/wishlist';
  static String wishlistJobPath(String jobId) => '$wishlistPath/jobs/$jobId';
  static String wishlistItemPath(String id) => '$wishlistPath/$id';
  static const String wishlistUnavailablePath = '$wishlistPath/unavailable';

  static const int pageSize = 20;
  static const int maxSearchLength = 100;

  static const String tabAll = 'all';
  static const String tabAvailable = 'available';
  static const String tabUnavailable = 'unavailable';
}
