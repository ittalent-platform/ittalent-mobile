Map<String, Object?> documentJson({
  String id = '507f1f77bcf86cd799439011',
  String type = 'cv',
  String name = 'Nguyễn Văn An.pdf',
  bool isDefault = false,
}) => {
  'id': id,
  'ownerId': '507f191e810c19729de860ea',
  'type': type,
  'fileUrl': 'https://storage.test/file',
  'fileName': name,
  'mimeType': 'application/pdf',
  'size': 350208,
  'isDefault': isDefault,
  'createdAt': '2026-10-22T03:00:00.000Z',
};
Map<String, Object?> pageJson(
  List<Map<String, Object?>> items, {
  int page = 1,
  int pages = 1,
}) => {
  'items': items,
  'page': page,
  'limit': 20,
  'total': 35,
  'totalPages': pages,
};
