class CertificateConstants {
  const CertificateConstants._();

  static const String listPath = '/api/v1/me/certificate-links';
  static String itemPath(String id) => '$listPath/$id';

  static const int pageSize = 20;
  static const int nameMaxLength = 200;
  static const int issuerMaxLength = 200;
  static const int urlMaxLength = 2048;
  static const int idempotencyKeyBytes = 16;
  static const String idempotencyHeader = 'Idempotency-Key';
  static const String codeVersionConflict = 'VERSION_CONFLICT';
  static const String codeDuplicateUrl = 'DUPLICATE_CERTIFICATE_URL';
  static const int searchMaxLength = 100;
  static const Duration searchDebounce = Duration(milliseconds: 400);
  static const double loadMoreThreshold = 240;

  static const String validityValid = 'valid';
  static const String validityExpired = 'expired';
  static const String validityNoExpiry = 'no_expiry';
  static const List<String> validities = [
    validityValid,
    validityExpired,
    validityNoExpiry,
  ];

  /// Translation key of a validity filter value.
  static String validityKey(String validity) => switch (validity) {
    validityValid => 'certificates.filter.valid',
    validityExpired => 'certificates.expired',
    _ => 'certificates.noExpiry',
  };

  /// Calendar day (YYYY-MM-DD) of a timestamp, in the device's time zone.
  static String day(DateTime value) =>
      value.toLocal().toIso8601String().substring(0, 10);
}
