import 'package:easy_localization/easy_localization.dart';

class CertificateConstants {
  const CertificateConstants._();

  static const String listPath = '/api/v1/me/certificate-links';
  static String itemPath(String id) => '$listPath/$id';

  static const int pageSize = 20;
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

  /// "12 Mar 2025" from a YYYY-MM-DD date.
  static String displayDate(String day) {
    final date = DateTime.tryParse(day);
    return date == null ? day : DateFormat('d MMM yyyy').format(date);
  }

  /// Calendar day (YYYY-MM-DD) of a timestamp, in the device's time zone.
  static String day(DateTime value) =>
      value.toLocal().toIso8601String().substring(0, 10);
}
