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

  test('Android destination channel selects before bytes and aborts only selected URI', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.example.ittalent_mobile/documents'),
          (call) async {
            calls.add(call.method);
            if (call.method == 'createDestination') {
              expect(call.arguments, {
                'name': 'Tiếng Việt.pdf',
                'mimeType': 'application/pdf',
              });
              return 'handle-one';
            }
            if (call.method == 'writeDestination') {
              final args = call.arguments as Map<Object?, Object?>;
              expect(args['handle'], 'handle-one');
              expect(args['bytes'], [0, 255, 1]);
              return 'content://documents/one';
            }
            expect(call.arguments, {'handle': 'handle-one'});
            return null;
          },
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.example.ittalent_mobile/documents'),
            null,
          ),
    );
    final destination = await DocumentFiles().prepareDownload(
      'Tiếng Việt.pdf',
      'application/pdf',
    );
    expect(calls, ['createDestination']);
    expect(
      await destination!.write(
        DownloadedDocument(
          Uint8List.fromList([0, 255, 1]),
          'Tiếng Việt.pdf',
          'application/pdf',
        ),
      ),
      Uri.parse('content://documents/one'),
    );
    await destination.abort();
    expect(calls, [
      'createDestination',
      'writeDestination',
      'abortDestination',
    ]);
  });
}
