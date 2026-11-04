import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/applicant/apply/apply_attempts.dart';

class _MemoryStore implements AttemptStore {
  final Map<String, String> data = {};
  bool broken = false;

  @override
  Future<String?> read(String name) async {
    if (broken) throw StateError('unreachable');
    return data[name];
  }

  @override
  Future<void> write(String name, String value) async {
    if (broken) throw StateError('unreachable');
    data[name] = value;
  }

  @override
  Future<void> delete(String name) async {
    if (broken) throw StateError('unreachable');
    data.remove(name);
  }
}

final RegExp _key = RegExp(r'^[0-9a-f]{32}$');

void main() {
  late DateTime clock;
  late _MemoryStore store;
  var seed = 0;

  /// An instance over [over]: what a new run of the app has, since only the
  /// store is shared between runs.
  ApplyAttempts attempts([_MemoryStore? over]) =>
      ApplyAttempts(over ?? store, now: () => clock, random: Random(seed++));

  setUp(() {
    clock = DateTime(2026, 11, 4, 12);
    store = _MemoryStore();
  });

  group('applyFingerprint', () {
    String fingerprint({
      String cvId = 'cv1',
      String? coverLetterId,
      String message = 'Hello',
      List<String> certificateIds = const ['a', 'b'],
    }) => applyFingerprint(
      jobId: 'j1',
      cvId: cvId,
      coverLetterId: coverLetterId,
      message: message,
      certificateIds: certificateIds,
    );

    test('is short, and the same for the same application', () {
      expect(fingerprint(), matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(fingerprint(), fingerprint());
    });

    test('ignores what the API ignores: spaces around the note, the order '
        'of the certificates', () {
      expect(
        fingerprint(message: '  Hello  ', certificateIds: ['b', 'a']),
        fingerprint(),
      );
    });

    test('changes with the CV, the cover letter, the note and the '
        'certificates', () {
      final base = fingerprint();
      expect(fingerprint(cvId: 'cv2'), isNot(base));
      expect(fingerprint(coverLetterId: 'cl1'), isNot(base));
      expect(fingerprint(message: 'Hi'), isNot(base));
      expect(fingerprint(certificateIds: ['a']), isNot(base));
    });
  });

  group('ApplyAttempts', () {
    const fingerprint = '429587ca1aeb6547';

    test('names an attempt with a key the API accepts', () async {
      final key = await attempts().keyFor(
        jobId: 'j1',
        fingerprint: fingerprint,
      );

      expect(key, matches(_key));
    });

    test('gives the same key to the same application until its outcome is '
        'known', () async {
      final run = attempts();
      final key = await run.keyFor(jobId: 'j1', fingerprint: fingerprint);

      expect(await run.keyFor(jobId: 'j1', fingerprint: fingerprint), key);

      await run.done('j1');

      expect(
        await run.keyFor(jobId: 'j1', fingerprint: fingerprint),
        isNot(key),
      );
    });

    test('starts a new attempt when the application changed', () async {
      final run = attempts();
      final key = await run.keyFor(jobId: 'j1', fingerprint: fingerprint);

      final changed = await run.keyFor(jobId: 'j1', fingerprint: 'other');

      expect(changed, isNot(key));
      expect(await run.keyFor(jobId: 'j1', fingerprint: 'other'), changed);
    });

    test('keeps one attempt per job', () async {
      final run = attempts();
      final first = await run.keyFor(jobId: 'j1', fingerprint: fingerprint);
      final second = await run.keyFor(jobId: 'j2', fingerprint: fingerprint);

      expect(second, isNot(first));
      expect(await run.keyFor(jobId: 'j1', fingerprint: fingerprint), first);
    });

    test('is still there after the app was closed', () async {
      final key = await attempts().keyFor(
        jobId: 'j1',
        fingerprint: fingerprint,
      );

      expect(
        await attempts().keyFor(jobId: 'j1', fingerprint: fingerprint),
        key,
      );
    });

    test('is gone once done, also for the next run of the app', () async {
      final key = await attempts().keyFor(
        jobId: 'j1',
        fingerprint: fingerprint,
      );
      await attempts().done('j1');

      expect(store.data, isEmpty);
      expect(
        await attempts().keyFor(jobId: 'j1', fingerprint: fingerprint),
        isNot(key),
      );
    });

    test('is forgotten when nobody sent again within an hour', () async {
      final key = await attempts().keyFor(
        jobId: 'j1',
        fingerprint: fingerprint,
      );

      clock = clock.add(const Duration(minutes: 59));
      expect(
        await attempts().keyFor(jobId: 'j1', fingerprint: fingerprint),
        key,
      );

      clock = clock.add(const Duration(minutes: 2));
      expect(
        await attempts().keyFor(jobId: 'j1', fingerprint: fingerprint),
        isNot(key),
      );
    });

    test('never throws when the device cannot keep it, and still serves a '
        'retry in the same run', () async {
      store.broken = true;
      final run = attempts();

      final key = await run.keyFor(jobId: 'j1', fingerprint: fingerprint);

      expect(key, matches(_key));
      expect(await run.keyFor(jobId: 'j1', fingerprint: fingerprint), key);
      await run.done('j1');
      expect(
        await run.keyFor(jobId: 'j1', fingerprint: fingerprint),
        isNot(key),
      );
    });

    test('ignores what it cannot read back', () async {
      store.data['ittalent_apply_attempt_j1'] = 'garbage';

      final key = await attempts().keyFor(
        jobId: 'j1',
        fingerprint: fingerprint,
      );

      expect(key, matches(_key));
    });
  });
}
