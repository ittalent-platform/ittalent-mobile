class DocumentConstants {
  const DocumentConstants._();
  static const path = '/api/v1/documents';
  static const maxBytes = 5000000;
  static const pageSize = 20;
  static const countPageSize = 1;
  static const searchLimit = 100;
  static const debounce = Duration(milliseconds: 300);
  static const signatures = {
    'pdf': [0x25, 0x50, 0x44, 0x46, 0x2d],
  };
  static const mimeTypes = {'pdf': 'application/pdf'};
}
