import 'apply_constants.dart';

/// Blank strings count as missing.
String? _text(Object? value) {
  final text = value is String ? value.trim() : '';
  return text.isEmpty ? null : text;
}

/// The first of [names] that is not blank; empty when none is.
String firstNonBlank(Iterable<String?> names) {
  for (final name in names) {
    final text = _text(name);
    if (text != null) return text;
  }
  return '';
}

/// The job being applied to, as the top of every step shows it.
class ApplyJob {
  const ApplyJob({
    required this.id,
    required this.title,
    required this.companyName,
    this.location,
    this.expiresAt,
  });

  final String id;
  final String title;
  final String companyName;
  final String? location;
  final DateTime? expiresAt;

  factory ApplyJob.fromJson(Map<String, dynamic> json) {
    final enterprise =
        (json['enterprise'] as Map<String, dynamic>?) ?? const {};
    return ApplyJob(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      companyName: enterprise['name'] as String? ?? '',
      location: _text(json['location']),
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
    );
  }

  /// A deadline that has passed closes the job, whatever the list said when
  /// it was read.
  bool isOpen(DateTime now) => expiresAt == null || !expiresAt!.isBefore(now);
}

/// A CV or cover letter of the applicant's library.
class ApplyDocument {
  const ApplyDocument({
    required this.id,
    required this.fileName,
    required this.size,
    required this.isDefault,
    this.createdAt,
  });

  final String id;
  final String fileName;
  final int size;
  final bool isDefault;
  final DateTime? createdAt;

  /// A malformed item is skipped rather than hiding the valid ones.
  static ApplyDocument? tryFromJson(Map<String, dynamic> json) {
    final id = _text(json['id']);
    final fileName = _text(json['fileName']);
    if (id == null || fileName == null) return null;
    return ApplyDocument(
      id: id,
      fileName: fileName,
      size: (json['size'] as num?)?.toInt() ?? 0,
      isDefault: json['isDefault'] == true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  /// The default document first, then the newest.
  static int defaultFirst(ApplyDocument a, ApplyDocument b) {
    if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
    final byDate = (b.createdAt?.millisecondsSinceEpoch ?? 0).compareTo(
      a.createdAt?.millisecondsSinceEpoch ?? 0,
    );
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  }

  /// The document the applicant chose if it is still in [documents], else
  /// the default one; null when neither exists (nothing is chosen for them).
  static String? chosen(List<ApplyDocument> documents, String? chosenId) {
    for (final document in documents) {
      if (document.id == chosenId) return document.id;
    }
    for (final document in documents) {
      if (document.isDefault) return document.id;
    }
    return null;
  }
}

/// A certificate link the applicant can send with the application.
class ApplyCertificate {
  const ApplyCertificate({
    required this.id,
    required this.name,
    required this.url,
    required this.suggested,
    this.expiryDate,
  });

  final String id;
  final String name;
  final String url;

  /// The applicant asked for it to be ticked on every application.
  final bool suggested;

  /// YYYY-MM-DD.
  final String? expiryDate;

  static ApplyCertificate? tryFromJson(Map<String, dynamic> json) {
    final id = _text(json['id']);
    final name = _text(json['name']);
    if (id == null || name == null) return null;
    return ApplyCertificate(
      id: id,
      name: name,
      url: json['url'] as String? ?? '',
      suggested: json['suggested'] == true,
      expiryDate: _text(json['expiryDate']),
    );
  }

  /// Host without "www.", shown instead of the full link.
  String get domain {
    final host = Uri.tryParse(url)?.host ?? '';
    if (host.isEmpty) return url;
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  bool get isHttps => url.startsWith('https://');

  /// Expiry dates are YYYY-MM-DD, so comparing the strings compares the dates.
  bool isExpired(DateTime now) =>
      expiryDate != null &&
      expiryDate!.compareTo(now.toUtc().toIso8601String().substring(0, 10)) < 0;
}

/// The latest application of the applicant to the job, if any.
class PreviousApplication {
  const PreviousApplication({
    required this.id,
    required this.canApplyAgain,
    this.status,
    this.withdrawnAt,
    this.companyName,
    this.sentByAttempt = false,
  });

  final String id;
  final bool canApplyAgain;
  final String? status;
  final DateTime? withdrawnAt;

  /// The company the application went to, as the application itself names it.
  /// It stays known when the job does not: once a job is closed the API no
  /// longer returns it, but the application still says whose it is.
  final String? companyName;

  /// True when this application is what an attempt that lost its answer
  /// created: it holds exactly what that attempt sent (BR-APP-009). The
  /// applicant is then told it was sent, as the answer would have said.
  final bool sentByAttempt;

  /// The same application, known to be the one the waiting attempt created.
  PreviousApplication asSentByAttempt() => PreviousApplication(
    id: id,
    canApplyAgain: canApplyAgain,
    status: status,
    withdrawnAt: withdrawnAt,
    companyName: companyName,
    sentByAttempt: true,
  );

  factory PreviousApplication.fromJson(Map<String, dynamic> json) {
    final job = json['job'];
    return PreviousApplication(
      id: json['id'] as String? ?? '',
      canApplyAgain: json['canApplyAgain'] as bool? ?? false,
      status: _text(json['status']),
      withdrawnAt: DateTime.tryParse(json['withdrawnAt'] as String? ?? ''),
      companyName: job is Map<String, dynamic>
          ? _text(job['companyName'])
          : null,
    );
  }
}

/// Why the flow stops before an application is sent. Each one has its own
/// page and way out.
enum ApplyBlock {
  emailNotVerified,
  jobClosed,
  alreadyApplied,
  applyAgainNotAllowed,
}

enum ApplyNoticeTone { error, warning, info }

/// A message of the flow: a translation key, what fills it in, and how it is
/// shown. [offline] swaps the icon for the "no connection" one.
class ApplyNotice {
  const ApplyNotice(
    this.key, {
    this.args = const {},
    this.tone = ApplyNoticeTone.error,
    this.offline = false,
  });

  final String key;
  final Map<String, String> args;
  final ApplyNoticeTone tone;
  final bool offline;
}

/// The sizes of an uploaded file for people: "412 KB", "6.1 MB".
String formatFileSize(int bytes) {
  String value(double amount) {
    final rounded = amount.toStringAsFixed(1);
    return rounded.endsWith('.0')
        ? rounded.substring(0, rounded.length - 2)
        : rounded;
  }

  if (bytes < ApplyConstants.bytesPerKilo) return '$bytes B';
  if (bytes < ApplyConstants.bytesPerMega) {
    return '${value(bytes / ApplyConstants.bytesPerKilo)} KB';
  }
  return '${value(bytes / ApplyConstants.bytesPerMega)} MB';
}

/// 1000 as "1,000": [separator] groups the digits by three.
String formatCount(int value, String separator) => value
    .toString()
    .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => separator);
