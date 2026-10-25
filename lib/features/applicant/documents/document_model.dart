import 'documents_constants.dart';

enum DocumentType {
  cv('cv'),
  coverLetter('cover_letter');

  const DocumentType(this.value);
  final String value;

  static DocumentType? tryParse(Object? value) {
    if (value is! String) return null;
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

class DocumentDto {
  const DocumentDto({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.isDefault,
    required this.createdAt,
  });
  final String id, ownerId, fileName, mimeType;
  final DocumentType type;
  final int size;
  final bool isDefault;
  final DateTime createdAt;
  factory DocumentDto.fromJson(Map<String, Object?> json) {
    final document = tryFromJson(json);
    if (document == null) throw const FormatException('Invalid document');
    return document;
  }

  /// A malformed list item is skipped rather than hiding valid documents.
  static DocumentDto? tryFromJson(Map<String, Object?> json) {
    final id = _requiredString(json['id']);
    final ownerId = _requiredString(json['ownerId']);
    final type = DocumentType.tryParse(json['type']);
    final fileName = _requiredString(json['fileName']);
    final mimeType = _requiredString(json['mimeType']);
    final size = _nonNegativeInt(json['size']);
    final isDefault = json['isDefault'];
    final createdAtRaw = json['createdAt'];
    final createdAt = createdAtRaw is String
        ? DateTime.tryParse(createdAtRaw)
        : null;
    if (id == null ||
        ownerId == null ||
        type == null ||
        fileName == null ||
        mimeType == null ||
        size == null ||
        isDefault is! bool ||
        createdAt == null) {
      return null;
    }
    return DocumentDto(
      id: id,
      ownerId: ownerId,
      type: type,
      fileName: fileName,
      mimeType: mimeType,
      size: size,
      isDefault: isDefault,
      createdAt: createdAt,
    );
  }
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
  factory DocumentsPage.fromJson(
    Map<String, Object?> json, {
    int fallbackPage = 1,
    int fallbackLimit = DocumentConstants.pageSize,
  }) {
    final items = <DocumentDto>[];
    final rawItems = json['items'];
    if (rawItems is List<Object?>) {
      for (final item in rawItems) {
        final map = _objectMap(item);
        if (map == null) continue;
        final document = DocumentDto.tryFromJson(map);
        if (document != null) items.add(document);
      }
    }
    final page = _positiveInt(json['page']) ?? fallbackPage;
    final limit = _positiveInt(json['limit']) ?? fallbackLimit;
    final total = _nonNegativeInt(json['total']) ?? items.length;
    final inferredTotalPages = total == 0 ? 1 : (total + limit - 1) ~/ limit;
    return DocumentsPage(
      items: items,
      page: page,
      limit: limit,
      total: total,
      totalPages: _nonNegativeInt(json['totalPages']) ?? inferredTotalPages,
    );
  }
}

class DocumentsQuery {
  const DocumentsQuery({this.type, this.search = ''});
  final DocumentType? type;
  final String search;
  Map<String, Object> parameters(
    int page, {
    int limit = DocumentConstants.pageSize,
  }) {
    final keyword = search.trim();
    if (page < 1 || limit < 1) throw ArgumentError('Invalid pagination');
    if (keyword.length > DocumentConstants.searchLimit) {
      throw ArgumentError('Search exceeds 100 characters');
    }
    return {
      'page': page,
      'limit': limit,
      'sort_by': 'created_at',
      'sort_order': 'desc',
      if (type != null) 'type': type!.value,
      if (keyword.isNotEmpty) 'search': keyword,
    };
  }
}

Map<String, Object?>? _objectMap(Object? value) {
  if (value is! Map<Object?, Object?>) return null;
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) return null;
    result[entry.key as String] = entry.value;
  }
  return result;
}

String? _requiredString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

int? _positiveInt(Object? value) => value is int && value > 0 ? value : null;

int? _nonNegativeInt(Object? value) =>
    value is int && value >= 0 ? value : null;
