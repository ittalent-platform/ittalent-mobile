import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_access_policy.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_files.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('picker cancellation and permission or I/O failures stay distinct', () {
    expect(
      DocumentFileException.fromPlatform(PlatformException(code: 'permission'))
          .failure,
      DocumentFileFailure.permissionDenied,
    );
    expect(
      DocumentFileException.fromPlatform(PlatformException(code: 'write'))
          .failure,
      DocumentFileFailure.io,
    );
    expect(
      DocumentFileException.fromPlatform(PlatformException(code: 'unsupported'))
          .failure,
      DocumentFileFailure.unsupported,
    );
  });

  test(
    'Android SAF and browser operations never request storage runtime access',
    () async {
      final policy = DocumentAccessPolicy();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      for (final operation in DocumentAccessOperation.values) {
        expect(
          (await policy.check(operation)).status,
          DocumentAccessStatus.notRequired,
        );
      }
      for (final platform in [
        TargetPlatform.iOS,
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        for (final operation in DocumentAccessOperation.values) {
          expect(
            (await policy.check(operation)).status,
            DocumentAccessStatus.notRequired,
          );
        }
      }
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      expect(
        (await policy.check(DocumentAccessOperation.uploadRead)).status,
        DocumentAccessStatus.unsupported,
      );
    },
  );
}
