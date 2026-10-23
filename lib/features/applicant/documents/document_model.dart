import 'documents_constants.dart';

enum DocumentType {
  cv('cv'),
  coverLetter('cover_letter');

  const DocumentType(this.value);
  final String value;
  static DocumentType parse(String value) =>
      values.firstWhere((e) => e.value == value);
}

class DocumentDto {
  const DocumentDto({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.fileUrl,
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.isDefault,
    required this.createdAt,
  });
  final String id, ownerId, fileUrl, fileName, mimeType;
  final DocumentType type;
  final int size;
  final bool isDefault;
  final DateTime createdAt;
  factory DocumentDto.fromJson(Map<String, Object?> json) => DocumentDto(
    id: json['id'] as String,
    ownerId: json['ownerId'] as String,
    type: DocumentType.parse(json['type'] as String),
    fileUrl: json['fileUrl'] as String,
    fileName: json['fileName'] as String,
    mimeType: json['mimeType'] as String,
    size: json['size'] as int,
    isDefault: json['isDefault'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class DocumentsPage {
  const DocumentsPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
  final List<DocumentDto> items;
  final int page, limit, total, totalPages;
  factory DocumentsPage.fromJson(Map<String, Object?> json) => DocumentsPage(
    items: (json['items'] as List<Object?>)
        .map((e) => DocumentDto.fromJson(Map<String, Object?>.from(e as Map)))
        .toList(),
    page: json['page'] as int,
    limit: json['limit'] as int,
    total: json['total'] as int,
    totalPages: json['totalPages'] as int,
  );
}

class DocumentsQuery {
  const DocumentsQuery({this.type, this.search = ''});
  final DocumentType? type;
  final String search;
  Map<String, Object> parameters(int page) {
    final keyword = search.trim();
    if (keyword.length > DocumentConstants.searchLimit) {
      throw ArgumentError('Search exceeds 100 characters');
    }
    return {
      'page': page,
      'limit': DocumentConstants.pageSize,
      'sort_by': 'created_at',
      'sort_order': 'desc',
      if (type != null) 'type': type!.value,
      if (keyword.isNotEmpty) 'search': keyword,
    };
  }
}
