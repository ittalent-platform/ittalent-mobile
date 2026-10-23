import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'documents_constants.dart';

class DocumentValidation implements Exception {
  const DocumentValidation(this.failure);
  final DocumentValidationFailure failure;
  String get key => failure.name;
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
    if (size == 0) {
      throw const DocumentValidation(DocumentValidationFailure.empty);
    }
    if (size > DocumentConstants.maxBytes) {
      throw const DocumentValidation(DocumentValidationFailure.size);
    }
    if (!name.contains('.') ||
        !DocumentConstants.mimeTypes.containsKey(extension)) {
      throw const DocumentValidation(DocumentValidationFailure.format);
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
    if (size == null) {
      throw const DocumentValidation(DocumentValidationFailure.read);
    }
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

class DownloadedDocument {
  const DownloadedDocument(this.bytes, this.name, this.mimeType);
  final Uint8List bytes;
  final String name, mimeType;
}

abstract class DocumentDestination {
  Future<Uri?> write(DownloadedDocument file);
  Future<void> abort();
}

String documentFileName(String? disposition, String fallback) {
  String? name;
  final utf = RegExp(
    r"filename\*\s*=\s*UTF-8''([^;]+)",
    caseSensitive: false,
  ).firstMatch(disposition ?? '');
  if (utf != null) {
    try {
      name = Uri.decodeComponent(utf.group(1)!.trim());
    } catch (_) {
      /* Try plain filename. */
    }
  }
  name ??=
      RegExp(
        r'filename\s*=\s*"([^"]+)"',
        caseSensitive: false,
      ).firstMatch(disposition ?? '')?.group(1) ??
      RegExp(
        r'filename\s*=\s*([^;]+)',
        caseSensitive: false,
      ).firstMatch(disposition ?? '')?.group(1);
  String clean(String value) => value
      .replaceAll(RegExp(r'[\x00-\x1f\x7f/\\:*?"<>|]'), '_')
      .replaceAll(RegExp(r'^\.+|[. ]+$'), '')
      .trim();
  final safe = clean(name ?? fallback);
  final result = safe.isEmpty ? clean(fallback) : safe;
  final reserved = RegExp(
    r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)',
    caseSensitive: false,
  );
  return result.isEmpty
      ? 'document'
      : reserved.hasMatch(result)
      ? '_$result'
      : result;
}
