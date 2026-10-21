import '../../../components/ui/app_badge.dart';

class ApplicationConstants {
  const ApplicationConstants._();

  static const String statusSubmitted = 'submitted';
  static const String statusUnderReview = 'under_review';
  static const String statusInterviewing = 'interviewing';
  static const String statusOffered = 'offered';
  static const String statusHired = 'hired';
  static const String statusRejected = 'rejected';
  static const String statusWithdrawn = 'withdrawn';
  static const String statusPositionFilled = 'position_filled';

  static const List<String> statuses = [
    statusSubmitted,
    statusUnderReview,
    statusInterviewing,
    statusOffered,
    statusHired,
    statusRejected,
    statusWithdrawn,
    statusPositionFilled,
  ];

  static const List<String> reviewStages = [
    'screening',
    'interview',
    'offer',
    'hired',
    'rejected',
  ];

  static const String sortSubmittedAt = 'submittedAt';
  static const String orderDescending = 'desc';
  static const String orderAscending = 'asc';

  static const String listPath = '/api/v1/me/applications';
  static const int pageSize = 20;
  static const int searchMaxLength = 100;
  static const Duration searchDebounce = Duration(milliseconds: 400);
  static const double loadMoreThreshold = 240;

  static BadgeTone badgeToneForStatus(String status) {
    switch (status) {
      case statusSubmitted:
        return BadgeTone.neutral;
      case statusUnderReview:
        return BadgeTone.info;
      case statusInterviewing:
        return BadgeTone.blocked;
      case statusOffered:
        return BadgeTone.warning;
      case statusHired:
        return BadgeTone.success;
      case statusRejected:
        return BadgeTone.error;
      default:
        return BadgeTone.neutral;
    }
  }

  /// Translation key of the status word; unknown statuses fall back to the raw value.
  static String statusKey(String status) =>
      statuses.contains(status) ? 'applications.status.$status' : status;
}
