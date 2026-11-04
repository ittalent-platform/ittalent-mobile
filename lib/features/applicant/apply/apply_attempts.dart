import 'dart:math';

/// Where the attempt that waits for an answer is kept: a small key-value
/// store. The app keeps it on the device (see `apply_providers.dart`), so it
/// outlives the app being closed.
abstract interface class AttemptStore {
  Future<String?> read(String name);

  Future<void> write(String name, String value);

  Future<void> delete(String name);
}

const int _mask = 0xFFFFFFFF;
const int _offset = 0x811c9dc5;
const int _prime = 0x01000193;
const int _otherOffset = 0x9747b28c;
const int _otherPrime = 0x85ebca6b;

String _hex(int value) => value.toRadixString(16).padLeft(8, '0');

/// A short stand-in for "this application, as it will be sent", so that a
/// changed CV, note or certificate starts a new attempt instead of reusing
/// the key of the old one. It hides the note rather than keeping its text on
/// the device. It is not a security measure: a collision only makes the API
/// refuse the key (409), and the next try starts a new attempt.
String applyFingerprint({
  required String jobId,
  required String cvId,
  String? coverLetterId,
  required String message,
  required List<String> certificateIds,
}) {
  final text = [
    jobId,
    cvId,
    coverLetterId ?? '',
    message.trim(),
    ([...certificateIds]..sort()).join(','),
  ].join('\u0000');
  var low = _offset;
  var high = _otherOffset;
  for (final unit in text.codeUnits) {
    low = ((low ^ unit) * _prime) & _mask;
    high = ((high ^ unit) * _otherPrime) & _mask;
  }
  return '${_hex(low)}${_hex(high)}';
}

class _Attempt {
  const _Attempt(this.key, this.fingerprint, this.savedAt);

  final String key;
  final String fingerprint;
  final DateTime savedAt;

  String get encoded =>
      [key, fingerprint, savedAt.millisecondsSinceEpoch].join('|');

  static _Attempt? tryParse(String raw) {
    final parts = raw.split('|');
    if (parts.length != 3 || parts[0].isEmpty || parts[1].isEmpty) return null;
    final millis = int.tryParse(parts[2]);
    if (millis == null) return null;
    return _Attempt(
      parts[0],
      parts[1],
      DateTime.fromMillisecondsSinceEpoch(millis),
    );
  }
}

/// The `Idempotency-Key` of the application being sent (BR-APP-009).
///
/// The key names one attempt. It is kept until the applicant knows the
/// outcome, so that sending again after a lost answer, even after the app was
/// closed in between, asks the API for the same application instead of
/// creating a second one.
///
/// It never throws: if the device cannot keep the attempt, the key still
/// works for as long as the app runs.
class ApplyAttempts {
  ApplyAttempts(this._store, {DateTime Function()? now, Random? random})
    : _now = now ?? DateTime.now,
      _random = random ?? Random.secure();

  /// An attempt that nobody sends again within this time is forgotten. It
  /// keeps an old key from naming an application that was dealt with since.
  static const Duration lifetime = Duration(hours: 1);

  static const String _prefix = 'ittalent_apply_attempt_';
  static const int _keyBytes = 16;
  static const int _byteValues = 256;

  final AttemptStore _store;
  final DateTime Function() _now;
  final Random _random;
  final Map<String, _Attempt> _kept = {};

  String _name(String jobId) => '$_prefix$jobId';

  String _newKey() => List.generate(
    _keyBytes,
    (_) => _random.nextInt(_byteValues).toRadixString(16).padLeft(2, '0'),
  ).join();

  Future<_Attempt?> _load(String jobId) async {
    final cached = _kept[jobId];
    if (cached != null) return cached;
    try {
      final raw = await _store.read(_name(jobId));
      final attempt = raw == null ? null : _Attempt.tryParse(raw);
      if (attempt != null) _kept[jobId] = attempt;
      return attempt;
    } on Object {
      return null;
    }
  }

  /// The key to send for this application: the one of the attempt that is
  /// still waiting for an answer, if it is the same content and recent
  /// enough, otherwise a new one (which is kept at once).
  Future<String> keyFor({
    required String jobId,
    required String fingerprint,
  }) async {
    final now = _now();
    final waiting = await _load(jobId);
    if (waiting != null &&
        waiting.fingerprint == fingerprint &&
        now.difference(waiting.savedAt) < lifetime) {
      return waiting.key;
    }
    final attempt = _Attempt(_newKey(), fingerprint, now);
    _kept[jobId] = attempt;
    try {
      await _store.write(_name(jobId), attempt.encoded);
    } on Object {
      // Kept in memory only: a retry in this run still reuses the key.
    }
    return attempt.key;
  }

  /// The outcome is known (the application was accepted, refused, or found
  /// to exist): the next attempt for this job is a new one.
  Future<void> done(String jobId) async {
    _kept.remove(jobId);
    try {
      await _store.delete(_name(jobId));
    } on Object {
      // Nothing was kept on the device, or it cannot be reached.
    }
  }
}
