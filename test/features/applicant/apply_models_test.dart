import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/applicant/apply/apply_constants.dart';
import 'package:ittalent_mobile/features/applicant/apply/apply_models.dart';

ApplyDocument _doc(String id, {bool isDefault = false, DateTime? createdAt}) =>
    ApplyDocument(
      id: id,
      fileName: '$id.pdf',
      size: 1,
      isDefault: isDefault,
      createdAt: createdAt,
    );

void main() {
  group('formatFileSize', () {
    test('uses bytes, KB and MB', () {
      expect(formatFileSize(999), '999 B');
      expect(formatFileSize(412000), '412 KB');
      expect(formatFileSize(6100000), '6.1 MB');
      expect(formatFileSize(5000000), '5 MB');
    });
  });

  group('formatCount', () {
    test('groups thousands with the language separator', () {
      expect(formatCount(1000, ','), '1,000');
      expect(formatCount(1000, '.'), '1.000');
      expect(formatCount(999, ','), '999');
      expect(formatCount(0, ','), '0');
    });
  });

  group('ApplyConstants', () {
    test('shows an application by the last four characters of its id', () {
      expect(ApplyConstants.displayId('65f0a1b2c3d4e5f6a7b89011'), 'APP-9011');
      expect(ApplyConstants.displayId('ab'), 'APP-AB');
    });

    test('a withdrawn or rejected application is closed', () {
      expect(ApplyConstants.closedStatuses.contains('withdrawn'), isTrue);
      expect(ApplyConstants.closedStatuses.contains('rejected'), isTrue);
      expect(ApplyConstants.closedStatuses.contains('pending'), isFalse);
    });
  });

  group('ApplyDocument', () {
    test('lists the default first, then the newest', () {
      final documents = [
        _doc('a', createdAt: DateTime(2026, 9, 20)),
        _doc('b', isDefault: true, createdAt: DateTime(2026, 10, 1)),
        _doc('c', createdAt: DateTime(2026, 10, 5)),
      ]..sort(ApplyDocument.defaultFirst);
      expect([for (final d in documents) d.id], ['b', 'c', 'a']);
    });

    test('the chosen document is the picked one, else the default', () {
      final documents = [_doc('b', isDefault: true), _doc('c'), _doc('a')];
      expect(ApplyDocument.chosen(documents, null), 'b');
      expect(ApplyDocument.chosen(documents, 'a'), 'a');
      // A document that is gone (deleted elsewhere) falls back to the default.
      expect(ApplyDocument.chosen(documents, 'zzz'), 'b');
    });

    test('nothing is chosen without a default, so the applicant picks', () {
      expect(ApplyDocument.chosen([_doc('b')], null), isNull);
      expect(ApplyDocument.chosen(const [], 'a'), isNull);
    });

    test('a document without a name is skipped', () {
      expect(ApplyDocument.tryFromJson({'id': 'x'}), isNull);
      final document = ApplyDocument.tryFromJson({
        'id': 'x',
        'fileName': 'f.pdf',
        'size': 12,
        'isDefault': true,
      });
      expect(document?.size, 12);
      expect(document?.isDefault, isTrue);
    });
  });

  group('ApplyCertificate', () {
    final link = ApplyCertificate.tryFromJson({
      'id': 'c1',
      'name': 'AWS Solutions Architect',
      'url': 'https://www.credly.com/badges/x',
      'suggested': true,
      'expiryDate': '2025-01-14',
    })!;

    test('shows the site of the link without www', () {
      expect(link.domain, 'credly.com');
      expect(link.isHttps, isTrue);
    });

    test('expires the day after its expiry date', () {
      expect(link.isExpired(DateTime.utc(2026, 11, 3)), isTrue);
      expect(link.isExpired(DateTime.utc(2025, 1, 14)), isFalse);
    });

    test('a plain http link without an expiry is not https, not expired', () {
      final plain = ApplyCertificate.tryFromJson({
        'id': 'c2',
        'name': 'Course',
        'url': 'http://example.org',
      })!;
      expect(plain.isHttps, isFalse);
      expect(plain.isExpired(DateTime.now()), isFalse);
    });
  });

  group('PreviousApplication and ApplyJob', () {
    test('reads when an application was withdrawn', () {
      final previous = PreviousApplication.fromJson({
        'id': 'p',
        'status': 'withdrawn',
        'canApplyAgain': true,
        'withdrawnAt': '2026-09-23T10:00:00Z',
      });
      expect(previous.canApplyAgain, isTrue);
      expect(previous.withdrawnAt?.month, 9);
    });

    test('names the company the application went to', () {
      final previous = PreviousApplication.fromJson({
        'id': 'p',
        'job': {'title': 'Backend', 'companyName': ' Nimbus Pay '},
      });
      expect(previous.companyName, 'Nimbus Pay');
      expect(previous.asSentByAttempt().companyName, 'Nimbus Pay');
    });

    test('an application whose job is missing or unnamed has no company', () {
      expect(PreviousApplication.fromJson({'id': 'p'}).companyName, isNull);
      expect(
        PreviousApplication.fromJson({
          'id': 'p',
          'job': {'companyName': ' '},
        }).companyName,
        isNull,
      );
      expect(
        PreviousApplication.fromJson({'id': 'p', 'job': 'oops'}).companyName,
        isNull,
      );
    });

    test('firstNonBlank takes the first name there is', () {
      expect(
        firstNonBlank([null, '', '  ', ' Nimbus Pay ', 'Other']),
        'Nimbus Pay',
      );
      expect(firstNonBlank([null, ' ']), '');
      expect(firstNonBlank(const []), '');
    });

    test('a job is open until its deadline', () {
      final job = ApplyJob.fromJson({
        'id': 'j',
        'title': 'T',
        'enterprise': {'name': 'Nimbus Pay'},
        'location': 'Ha Noi',
        'expiresAt': '2026-10-20T00:00:00Z',
      });
      expect(job.isOpen(DateTime.utc(2026, 10, 19)), isTrue);
      expect(job.isOpen(DateTime.utc(2026, 10, 21)), isFalse);
    });
  });
}
