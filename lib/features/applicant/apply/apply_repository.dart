import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/client.dart';
import 'apply_attempts.dart';
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

  /// Every item of a paged list, page after page, so that an applicant with
  /// more than one page of CVs or certificate links still sees them all.
  ///
  /// It stops at a short page, once [total] items are read, or when a page
  /// brings nothing new (a server that ignores `page` must not loop for ever).
  Future<List<Map<String, dynamic>>> _allPages(
    String path, {
    Map<String, dynamic> query = const {},
  }) async {
    final items = <Map<String, dynamic>>[];
    final seen = <Object?>{};
    for (var page = 1; ; page++) {
      final response = await client.get<Map<String, dynamic>>(
        path,
        queryParameters: {
          ...query,
          'page': page,
          'limit': ApplyConstants.listLimit,
        },
      );
      final received = _items(response.data);
      final fresh = [
        for (final item in received)
          if (seen.add(item['id'])) item,
      ];
      items.addAll(fresh);
      final total = response.data?['total'];
      final isLast =
          fresh.isEmpty ||
          received.length < ApplyConstants.listLimit ||
          (total is int && items.length >= total);
      if (isLast) return items;
    }
  }

  Future<ApplyJob> job(String id) async {
    final response = await client.get<Map<String, dynamic>>(
      ApplyConstants.jobPath(id),
    );
    return ApplyJob.fromJson(response.data ?? const {});
  }

  /// All the CVs or cover letters of the applicant: the default one first,
  /// then the newest.
  Future<List<ApplyDocument>> documents(String type) async {
    final items = await _allPages(
      ApplyConstants.documentsPath,
      query: {'type': type},
    );
    return [for (final item in items) ?ApplyDocument.tryFromJson(item)]
      ..sort(ApplyDocument.defaultFirst);
  }

  /// All the certificate links of the applicant. The choice is final only
  /// when every page was read, so a failure on any page fails the list.
  Future<List<ApplyCertificate>> certificates() async {
    final items = await _allPages(ApplyConstants.certificatesPath);
    return [for (final item in items) ?ApplyCertificate.tryFromJson(item)];
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

  /// What the application [id] holds, as an [applyFingerprint]: the CV, the
  /// cover letter, the note and the certificates it was sent with. It is how
  /// an application is told to be (or not to be) what an attempt sent.
  Future<String> fingerprintOf(String id, String jobId) async {
    final response = await client.get<Map<String, dynamic>>(
      ApplyConstants.applicationPath(id),
    );
    final data = response.data ?? const <String, dynamic>{};

    // The document of one kind among what the application attached.
    String? attached(String type) {
      for (final item in (data['attachments'] as List<dynamic>?) ?? const []) {
        if (item is Map<String, dynamic> && item['type'] == type) {
          return item['documentId'] as String?;
        }
      }
      return null;
    }

    return applyFingerprint(
      jobId: jobId,
      cvId: attached(ApplyConstants.typeCv) ?? '',
      coverLetterId: attached(ApplyConstants.typeCoverLetter),
      message: data['message'] as String? ?? '',
      certificateIds: [
        for (final item in (data['certificates'] as List<dynamic>?) ?? const [])
          if (item is Map<String, dynamic> && item['id'] is String)
            item['id'] as String,
      ],
    );
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

  /// Sends the application and returns its id. With an [idempotencyKey], a
  /// second send of the same attempt (after a lost answer) returns the
  /// application the first one created, not a new one.
  Future<String> submit({
    required String jobId,
    required String cvId,
    String? coverLetterId,
    String? message,
    List<String> certificateIds = const [],
    String? idempotencyKey,
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
      options: idempotencyKey == null
          ? null
          : Options(
              headers: {ApplyConstants.idempotencyHeader: idempotencyKey},
            ),
    );
    return (response.data?['id'] as String?) ?? '';
  }
}

final applyRepositoryProvider = Provider<ApplyRepository>(
  (ref) => ApplyRepository(ref.watch(apiClientProvider)),
);
