import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class DocumentFiles {
  Future<SelectedDocument?> pick() async {
    final PlatformFile? file;
    try {
      file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: DocumentConstants.mimeTypes.keys.toList(),
      );
    } on PlatformException catch (error) {
      throw DocumentFileException.fromPlatform(error);
    }
    if (file == null) return null;
    final selectedFile = file;
    final int? size;
    try {
      size = await file.length();
    } on PlatformException catch (error) {
      throw DocumentFileException.fromPlatform(error);
    } catch (_) {
      throw const DocumentFileException(DocumentFileFailure.io);
    }
    if (size == null) throw const DocumentValidation('read');
    return SelectedDocument(
      name: file.name,
      size: size,
      readBytes: () async {
        try {
          return await selectedFile.readAsBytes();
        } on PlatformException catch (error) {
          throw DocumentFileException.fromPlatform(error);
        } catch (_) {
          throw const DocumentFileException(DocumentFileFailure.io);
        }
      },
    );
  }
}

final documentFilesProvider = Provider<DocumentFiles>((ref) => DocumentFiles());
