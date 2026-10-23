import 'package:flutter/services.dart';

import 'documents_constants.dart';

class DocumentValidation implements Exception {
  const DocumentValidation(this.key);
  final String key;
}

enum DocumentFileFailure { permissionDenied, io, unsupported }

class DocumentFileException implements Exception {
  const DocumentFileException(this.failure);
  final DocumentFileFailure failure;

  static DocumentFileException fromPlatform(PlatformException error) {
    final code = error.code.toLowerCase();
    if (code.contains('permission') || code.contains('security')) {
      return const DocumentFileException(DocumentFileFailure.permissionDenied);
    }
    if (code == 'unsupported') {
      return const DocumentFileException(DocumentFileFailure.unsupported);
    }
    return const DocumentFileException(DocumentFileFailure.io);
  }
}

class SelectedDocument {
  const SelectedDocument({
    required this.name,
    required this.size,
    required this.readBytes,
  });
  final String name;
  final int size;
  final Future<Uint8List> Function() readBytes;
  String get extension => name.split('.').last.toLowerCase();
  String get mimeType => DocumentConstants.mimeTypes[extension]!;
  void validate() {
    if (size == 0) throw const DocumentValidation('empty');
    if (size > DocumentConstants.maxBytes) {
      throw const DocumentValidation('size');
    }
    if (!name.contains('.') ||
        !DocumentConstants.mimeTypes.containsKey(extension)) {
      throw const DocumentValidation('format');
    }
  }
}
