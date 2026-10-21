class PortfolioConstants {
  const PortfolioConstants._();

  static const String listPath = '/api/v1/me/portfolio-links';
  static String itemPath(String id) => '$listPath/$id';

  static const int pageSize = 20;
  static const int titleMaxLength = 200;
  static const int descriptionMaxLength = 1000;
  static const int urlMaxLength = 2048;
  static const int idempotencyKeyBytes = 16;
  static const String idempotencyHeader = 'Idempotency-Key';
  static const String codeVersionConflict = 'VERSION_CONFLICT';
  static const String codeDuplicateUrl = 'DUPLICATE_PORTFOLIO_URL';
  static const double loadMoreThreshold = 240;
}
