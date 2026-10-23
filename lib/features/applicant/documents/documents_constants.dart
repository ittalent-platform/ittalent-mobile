class DocumentConstants {
  const DocumentConstants._();
  static const path = '/api/v1/documents';
  static const bytesPerKiB = 1024;
  static const bytesPerMiB = bytesPerKiB * bytesPerKiB;
  static const errorResponseMaxBytes = 64 * bytesPerKiB;
  static const maxBytes = 5 * bytesPerMiB;
  static const pageSize = 20;
  static const searchLimit = 100;
  static const debounce = Duration(milliseconds: 300);
  static const signatures = {
    'pdf': [0x25, 0x50, 0x44, 0x46, 0x2d],
    'doc': [0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1, 0x1a, 0xe1],
    'docx': [0x50, 0x4b, 0x03, 0x04],
  };
  static const mimeTypes = {
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  };
}

enum DocumentValidationFailure { empty, size, format, read }

enum DocumentDownloadPhase { checking, choosing, downloading, saving }
