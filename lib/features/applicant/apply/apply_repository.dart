import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/client.dart';
import 'apply_constants.dart';
import 'apply_files.dart';
import 'apply_models.dart';

/// Everything the apply flow reads and writes. It has its own data layer so
/// that the flow does not depend on the slices of the documents, certificates
/// and applications screens; the app wires the caches together (see
/// `applicationSubmittedProvider`).
class ApplyRepository {
  ApplyRepository(this.client);

  final ApiClient client;

  List<Map<String, dynamic>> _items(Map<String, dynamic>? data) => [
    for (final item in (data?['items'] as List<dynamic>?) ?? const [])
      if (item is Map<String, dynamic>) item,
  ];

  Future<ApplyJob> job(String id) async {
    final response = await client.get<Map<String, dynamic>>(
      ApplyConstants.jobPath(id),
    );
    return ApplyJob.fromJson(response.data ?? const {});
  }

  /// The CVs or cover letters of the applicant (first page of up to 100):
  /// the default one first, then the newest.
  Future<List<ApplyDocument>> documents(String type) async {
    final response = await client.get<Map<String, dynamic>>(
      ApplyConstants.documentsPath,
      queryParameters: {
        'type': type,
        'page': 1,
        'limit': ApplyConstants.listLimit,
      },
    );
    return [
      for (final item in _items(response.data))
        ?ApplyDocument.tryFromJson(item),
    ]..sort(ApplyDocument.defaultFirst);
  }

  Future<List<ApplyCertificate>> certificates() async {
    final response = await client.get<Map<String, dynamic>>(
      ApplyConstants.certificatesPath,
      queryParameters: {'page': 1, 'limit': ApplyConstants.listLimit},
    );
    return [
      for (final item in _items(response.data))
        ?ApplyCertificate.tryFromJson(item),
    ];
  }

  /// The latest application of the applicant to the job, or null.
  Future<PreviousApplication?> previous(String jobId) async {
    final response = await client.get<Map<String, dynamic>>(
      ApplyConstants.applicationsPath,
      queryParameters: {'jobId': jobId, 'page': 1, 'limit': 1},
    );
    final items = _items(response.data);
    return items.isEmpty ? null : PreviousApplication.fromJson(items.first);
  }

  /// Saves [file] to the applicant's documents, as the documents screen does.
  /// Throws [ApplyFileException] for a file that fails the checks.
  Future<ApplyDocument> upload(ApplyPickedFile file, String type) async {
    final Uint8List bytes = await file.validatedBytes();
    FormData body() => FormData.fromMap({
      ApplyConstants.typeField: type,
      ApplyConstants.fileField: MultipartFile.fromBytes(
        bytes,
        filename: file.name,
        contentType: DioMediaType.parse(ApplyConstants.pdfMimeType),
      ),
    });
    final response = await client.post<Map<String, dynamic>>(
      ApplyConstants.documentsPath,
      data: body(),
      options: Options(
        contentType: 'multipart/form-data',
        extra: {'replayBody': body},
      ),
    );
    final document = ApplyDocument.tryFromJson(response.data ?? const {});
    if (document == null) {
      throw ApplyFileException(ApplyFileProblem.unreadable, file);
    }
    return document;
  }

  /// Sends the application and returns its id.
  Future<String> submit({
    required String jobId,
    required String cvId,
    String? coverLetterId,
    String? message,
    List<String> certificateIds = const [],
  }) async {
    final response = await client.post<Map<String, dynamic>>(
      ApplyConstants.submitPath,
      data: {
        'jobPostingId': jobId,
        'cvId': cvId,
        'coverLetterId': ?coverLetterId,
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
        if (certificateIds.isNotEmpty) 'certificateLinkIds': certificateIds,
      },
    );
    return (response.data?['id'] as String?) ?? '';
  }
}

final applyRepositoryProvider = Provider<ApplyRepository>(
  (ref) => ApplyRepository(ref.watch(apiClientProvider)),
);
