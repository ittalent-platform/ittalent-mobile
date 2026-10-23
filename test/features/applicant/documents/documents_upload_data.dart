import 'dart:typed_data';

import 'package:ittalent_mobile/features/applicant/documents/document_files.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_constants.dart';

SelectedDocument selected(String extension, {int? size, Uint8List? bytes}) {
  final content =
      bytes ??
      Uint8List.fromList([
        ...DocumentConstants.signatures[extension] ?? [1],
        0,
        1,
        255,
      ]);
  return SelectedDocument(
    name: 'Nguyễn Văn An.$extension',
    size: size ?? content.length,
    readBytes: () async => content,
  );
}
