import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/client.dart';
import '../../../api/api_error.dart';
import 'document_files.dart';
import 'document_model.dart';
import 'documents_constants.dart';

sealed class DocumentPreview {
  const DocumentPreview();
}

class PdfDocumentPreview extends DocumentPreview {
  const PdfDocumentPreview(this.bytes);
  final Uint8List bytes;
}

class UrlDocumentPreview extends DocumentPreview {
  const UrlDocumentPreview(this.url);
  final Uri url;
}

class DocumentsRepository {
  DocumentsRepository(this.client);
  final ApiClient client;
  Future<DocumentsPage> list(
    DocumentsQuery query,
    int page, {
    int limit = DocumentConstants.pageSize,
  }) async {
    final response = await client.get<Map<String, Object?>>(
      DocumentConstants.path,
      queryParameters: query.parameters(page, limit: limit),
    );
    return DocumentsPage.fromJson(
      response.data ?? const <String, Object?>{},
      fallbackPage: page,
      fallbackLimit: limit,
    );
  }

  Future<int> count(DocumentsQuery query) async =>
      (await list(query, 1, limit: DocumentConstants.countPageSize)).total;

  Future<DocumentDto> setDefault(String id) async {
    try {
      final response = await client.dio.patch<Map<String, Object?>>(
        '${DocumentConstants.path}/${Uri.encodeComponent(id)}/default',
      );
      if (response.statusCode != 200 || response.data == null) {
        throw ApiError(
          message: 'Unexpected set-default status',
          statusCode: response.statusCode,
        );
      }
      return DocumentDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      final response = await client.dio.delete<void>(
        '${DocumentConstants.path}/${Uri.encodeComponent(id)}',
      );
      if (response.statusCode != 204) {
        throw ApiError(
          message: 'Unexpected delete status',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiError.fromDio(e);
    }
  }

  Future<DocumentPreview> preview(String id) async {
    try {
      final response = await client.dio.get<List<int>>(
        '${DocumentConstants.path}/${Uri.encodeComponent(id)}/preview',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/pdf, application/json'},
        ),
      );
      final bytes = response.data;
      final mime = response.headers
          .value(Headers.contentTypeHeader)
          ?.split(';')
          .first
          .trim()
          .toLowerCase();
      final length = int.tryParse(
        response.headers.value(Headers.contentLengthHeader) ?? '',
      );
      if (response.statusCode == 200 && bytes != null && bytes.isNotEmpty) {
        if (mime == DocumentConstants.mimeTypes['pdf'] &&
            bytes.length >= DocumentConstants.signatures['pdf']!.length &&
            bytes.length == (length ?? bytes.length)) {
          final signature = DocumentConstants.signatures['pdf']!;
          if (List.generate(
            signature.length,
            (index) => bytes[index] == signature[index],
          ).every((match) => match)) {
            return PdfDocumentPreview(Uint8List.fromList(bytes));
          }
        } else if (mime == Headers.jsonContentType) {
          try {
            final Object? data = jsonDecode(utf8.decode(bytes));
            if (data is Map<String, Object?>) {
              final rawUrl = data['previewUrl'];
              final url = rawUrl is String ? Uri.tryParse(rawUrl) : null;
              if (url != null &&
                  url.host.isNotEmpty &&
                  (url.scheme == 'https' || url.scheme == 'http')) {
                return UrlDocumentPreview(url);
              }
            }
          } on FormatException {
            // A malformed legacy response is handled below.
          }
        }
      }
      throw ApiError(
        message: 'Invalid document preview response',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      _decodeByteError(e);
      throw ApiError.fromDio(e);
    }
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

  Future<DownloadedDocument> download(
    DocumentDto item, {
    CancelToken? cancelToken,
    ProgressCallback? onProgress,
  }) async {
    try {
      final response = await client.dio.get<List<int>>(
        '${DocumentConstants.path}/${Uri.encodeComponent(item.id)}/download',
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/pdf'},
        ),
      );
      final mime =
          response.headers
              .value(Headers.contentTypeHeader)
              ?.split(';')
              .first
              .trim() ??
          item.mimeType;
      final bytes = response.data;
      final length = int.tryParse(
        response.headers.value(Headers.contentLengthHeader) ?? '',
      );
      if (response.statusCode != 200 ||
          bytes == null ||
          bytes.isEmpty ||
          !DocumentConstants.mimeTypes.containsValue(mime) ||
          (length != null && length != bytes.length)) {
        throw const ApiError(message: 'Invalid document response');
      }
      return DownloadedDocument(
        Uint8List.fromList(bytes),
        documentFileName(
          response.headers.value('content-disposition'),
          item.fileName,
        ),
        mime,
      );
    } on DioException catch (e) {
      _decodeByteError(e);
      throw ApiError.fromDio(e);
    }
  }
}

void _decodeByteError(DioException error) {
  final data = error.response?.data;
  if (data is List<int> && data.length < 65536) {
    try {
      error.response?.data = jsonDecode(utf8.decode(data));
    } on FormatException {
      // Non-JSON server error.
    }
  }
}

final documentsRepositoryProvider = Provider<DocumentsRepository>(
  (ref) => DocumentsRepository(ref.watch(apiClientProvider)),
);
