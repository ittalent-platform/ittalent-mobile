/// Values of the apply flow (UC-BJOB-03): where it reads and writes, the
/// limits of an uploaded file and the codes the API answers with.
class ApplyConstants {
  const ApplyConstants._();

  static String jobPath(String id) => '/api/v1/job-postings/$id/public';
  static const String submitPath = '/api/v1/applications';
  static const String applicationsPath = '/api/v1/me/applications';
  static const String documentsPath = '/api/v1/documents';
  static const String certificatesPath = '/api/v1/me/certificate-links';

  static const String typeCv = 'cv';
  static const String typeCoverLetter = 'cover_letter';

  /// The API serves at most 100 items a page; the first page of each list is
  /// what the applicant chooses from.
  static const int listLimit = 100;

  static const int totalSteps = 2;

  /// A file is a PDF of 1 byte to 5 MB (decimal, as the documents screen).
  static const int maxFileBytes = 5000000;
  static const int bytesPerKilo = 1000;
  static const int bytesPerMega = 1000000;
  static const String pdfExtension = 'pdf';
  static const List<String> wordExtensions = ['doc', 'docx'];
  static const List<int> pdfSignature = [0x25, 0x50, 0x44, 0x46, 0x2d];
  static const String pdfMimeType = 'application/pdf';
  static const String fileField = 'file';
  static const String typeField = 'type';

  /// At most this many certificate links go with one application.
  static const int maxCertificates = 20;

  /// The note to the company is 0–1,000 characters.
  static const int messageMaxLength = 1000;
  static const int messageMinLines = 3;
  static const int messageMaxLines = 6;

  /// The reference shown for an application, as on the web ("APP-9011").
  static String displayId(String id) =>
      'APP-${(id.length > 4 ? id.substring(id.length - 4) : id).toUpperCase()}';

  // Codes of the API (`code` of an error body).
  static const String codeEmailNotVerified = 'EMAIL_NOT_VERIFIED';
  static const String codeAccountNotActive = 'ACCOUNT_NOT_ACTIVE';
  static const String codeJobUnavailable = 'JOB_UNAVAILABLE';
  static const String codePositionFilled = 'POSITION_FILLED';
  static const String codeInvalidCv = 'INVALID_CV';
  static const String codeInvalidCoverLetter = 'INVALID_COVER_LETTER';
  static const String codeAlreadyApplied = 'ALREADY_APPLIED';
  static const String codeApplyAgainNotAllowed = 'APPLY_AGAIN_NOT_ALLOWED';
  static const String codeCertificateUnavailable = 'CERTIFICATE_UNAVAILABLE';

  /// An application in one of these statuses is over: the applicant may send
  /// a new one (twice at most, as the API counts).
  static const String statusWithdrawn = 'withdrawn';
  static const String statusRejected = 'rejected';
  static const List<String> closedStatuses = [statusWithdrawn, statusRejected];

  static const int statusNotFound = 404;
  static const int statusBadRequest = 400;
}
