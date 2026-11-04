import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'apply_constants.dart';

/// Why a picked file cannot be uploaded.
enum ApplyFileProblem { empty, tooLarge, notPdf, wordFile, unreadable }

class ApplyFileException implements Exception {
  const ApplyFileException(this.problem, this.file);

  final ApplyFileProblem problem;
  final ApplyPickedFile file;
}

/// A file the applicant picked. It is checked before anything is sent: the
/// name says PDF, the size is 1 byte to 5 MB, and the bytes start with
/// `%PDF-`, as the API checks them too.
class ApplyPickedFile {
  const ApplyPickedFile({
    required this.name,
    required this.size,
    required this.readBytes,
  });

  final String name;
  final int size;
  final Future<Uint8List> Function() readBytes;

  String get extension =>
      name.contains('.') ? name.split('.').last.toLowerCase() : '';

  /// The problem visible without reading the file, or null.
  ApplyFileProblem? get problem {
    if (extension != ApplyConstants.pdfExtension) {
      return ApplyConstants.wordExtensions.contains(extension)
          ? ApplyFileProblem.wordFile
          : ApplyFileProblem.notPdf;
    }
    if (size <= 0) return ApplyFileProblem.empty;
    if (size > ApplyConstants.maxFileBytes) return ApplyFileProblem.tooLarge;
    return null;
  }

  /// Reads the file and returns its bytes, or throws [ApplyFileException].
  /// The size is checked again on what was read: the picker's metadata of a
  /// cloud file can be stale.
  Future<Uint8List> validatedBytes() async {
    final first = problem;
    if (first != null) throw ApplyFileException(first, this);
    final Uint8List bytes;
    try {
      bytes = await readBytes();
    } on Object {
      throw ApplyFileException(ApplyFileProblem.unreadable, this);
    }
    if (bytes.isEmpty) throw ApplyFileException(ApplyFileProblem.empty, this);
    if (bytes.length > ApplyConstants.maxFileBytes) {
      throw ApplyFileException(ApplyFileProblem.tooLarge, this);
    }
    final signature = ApplyConstants.pdfSignature;
    final isPdf =
        bytes.length >= signature.length &&
        [for (var i = 0; i < signature.length; i++) bytes[i] == signature[i]]
            .every((match) => match);
    if (!isPdf) throw ApplyFileException(ApplyFileProblem.notPdf, this);
    return bytes;
  }
}

/// The system file picker. Any file can be chosen, so that a Word file is
/// told apart from other files in the message instead of being hidden.
class ApplyFiles {
  const ApplyFiles();

  /// The chosen file, or null when the picker was closed. A file that cannot
  /// be reached throws [ApplyFileException].
  Future<ApplyPickedFile?> pick() async {
    final PlatformFile? file;
    try {
      file = await FilePicker.pickFile(type: FileType.any);
    } on PlatformException {
      return null;
    }
    if (file == null) return null;
    final picked = file;
    int? size;
    try {
      size = await picked.length();
    } on Object {
      size = null;
    }
    final result = ApplyPickedFile(
      name: picked.name,
      size: size ?? 0,
      readBytes: () => picked.readAsBytes(),
    );
    if (size == null) {
      throw ApplyFileException(ApplyFileProblem.unreadable, result);
    }
    return result;
  }
}

final applyFilesProvider = Provider<ApplyFiles>((ref) => const ApplyFiles());
