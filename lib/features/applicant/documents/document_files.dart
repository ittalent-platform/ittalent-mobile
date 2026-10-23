import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class DownloadedDocument {
  const DownloadedDocument(this.bytes, this.name, this.mimeType);
  final Uint8List bytes;
  final String name, mimeType;
}

abstract class DocumentDestination {
  Future<Uri?> write(DownloadedDocument file);
  Future<void> abort();
}

class _DeferredDestination implements DocumentDestination {
  @override
  Future<Uri?> write(DownloadedDocument file) => FilePicker.saveFile(
    fileName: file.name,
    bytes: file.bytes,
    mimeType: file.mimeType,
  );

  @override
  Future<void> abort() async {}
}

class _AndroidDestination implements DocumentDestination {
  _AndroidDestination(this._handle);
  final String _handle;
  static const _channel = MethodChannel(
    'com.example.ittalent_mobile/documents',
  );

  @override
  Future<Uri?> write(DownloadedDocument file) async {
    try {
      final value = await _channel.invokeMethod<String>('writeDestination', {
        'handle': _handle,
        'bytes': file.bytes,
      });
      return value == null ? null : Uri.tryParse(value);
    } on PlatformException catch (error) {
      throw DocumentFileException.fromPlatform(error);
    }
  }

  @override
  Future<void> abort() async =>
      _channel.invokeMethod<void>('abortDestination', {'handle': _handle});
}

/// The OS owns location selection, duplicate-name confirmation, and cancellation.
/// A non-null URI means that writing has completed, not just that a path was picked.
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

  Future<Uri?> save(DownloadedDocument file) => FilePicker.saveFile(
    fileName: file.name,
    bytes: file.bytes,
    mimeType: file.mimeType,
  );

  /// On Android, ACTION_CREATE_DOCUMENT returns a writable URI before GET.
  /// Other supported targets use their save UI after bytes are available.
  Future<DocumentDestination?> prepareDownload(
    String name,
    String mimeType,
  ) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const channel = MethodChannel('com.example.ittalent_mobile/documents');
      final String? handle;
      try {
        handle = await channel.invokeMethod<String>('createDestination', {
          'name': name,
          'mimeType': mimeType,
        });
      } on PlatformException catch (error) {
        throw DocumentFileException.fromPlatform(error);
      }
      return handle == null ? null : _AndroidDestination(handle);
    }
    return _DeferredDestination();
  }
}

final documentFilesProvider = Provider<DocumentFiles>((ref) => DocumentFiles());

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
