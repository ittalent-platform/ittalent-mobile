import '../../../components/ui/app_badge.dart';

class ApplicationConstants {
  const ApplicationConstants._();

  static const String statusSubmitted = 'submitted';
  static const String statusReview = 'review';
  static const String statusInterview = 'interview';
  static const String statusOffered = 'offered';
  static const String statusHired = 'hired';
  static const String statusRejected = 'rejected';
  static const String statusWithdrawn = 'withdrawn';

  static BadgeTone badgeToneForStatus(String status) {
    switch (status.toLowerCase()) {
      case statusSubmitted:
        return BadgeTone.neutral;
      case statusReview:
        return BadgeTone.info;
      case statusInterview:
        return BadgeTone.blocked;
      case statusOffered:
        return BadgeTone.warning;
      case statusHired:
        return BadgeTone.success;
      case statusRejected:
        return BadgeTone.error;
      case statusWithdrawn:
      default:
        return BadgeTone.neutral;
    }
  }

  static String labelForStatus(String status) {
    switch (status.toLowerCase()) {
      case statusSubmitted:
        return 'Submitted';
      case statusReview:
        return 'In Review';
      case statusInterview:
        return 'Interview';
      case statusOffered:
        return 'Offered';
      case statusHired:
        return 'Hired';
      case statusRejected:
        return 'Rejected';
      case statusWithdrawn:
        return 'Withdrawn';
      default:
        return status;
    }
  }
}
