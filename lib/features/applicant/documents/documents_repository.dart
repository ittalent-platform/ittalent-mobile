import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/client.dart';
import '../../../api/api_error.dart';
import 'document_files.dart';
import 'document_model.dart';
import 'documents_constants.dart';

class DocumentsRepository {
  DocumentsRepository(this.client);
  final ApiClient client;
  Future<DocumentsPage> list(DocumentsQuery query, int page) async {
    final response = await client.get<Map<String, Object?>>(
      DocumentConstants.path,
      queryParameters: query.parameters(page),
    );
    return DocumentsPage.fromJson(response.data!);
  }

  Future<DocumentDto> upload(
    SelectedDocument file,
    DocumentType type, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    file.validate();
    late final Uint8List bytes;
    try {
      bytes = await file.readBytes();
    } on DocumentFileException {
      rethrow;
    } catch (_) {
      // The selected provider may revoke access, remove the file, or go offline.
      throw const DocumentValidation('read');
    }
    // Validate again after reading: cloud-backed picker metadata may be stale.
    SelectedDocument(
      name: file.name,
      size: bytes.length,
      readBytes: () async => bytes,
    ).validate();
    final signature = DocumentConstants.signatures[file.extension]!;
    if (bytes.length < signature.length ||
        !List.generate(
          signature.length,
          (i) => bytes[i] == signature[i],
        ).every((match) => match)) {
      throw const DocumentValidation('format');
    }
    FormData createBody() => FormData.fromMap({
      'type': type.value,
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.name,
        contentType: DioMediaType.parse(file.mimeType),
      ),
    });
    try {
      final response = await client.dio.post<Map<String, Object?>>(
        DocumentConstants.path,
        data: createBody(),
        cancelToken: cancelToken,
        onSendProgress: onProgress,
        options: Options(
          contentType: 'multipart/form-data',
          extra: {'replayBody': createBody},
        ),
      );
      if (response.statusCode != 201) {
        throw ApiError(
          message: 'Unexpected upload status',
          statusCode: response.statusCode,
        );
      }
      return DocumentDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    }
  }
}

final documentsRepositoryProvider = Provider<DocumentsRepository>(
  (ref) => DocumentsRepository(ref.watch(apiClientProvider)),
);
