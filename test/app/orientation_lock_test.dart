import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Screen Orientation Lock Tests', () {
    test(
      'SystemChrome.setPreferredOrientations requests portrait mode only',
      () async {
        final log = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (
              MethodCall methodCall,
            ) async {
              log.add(methodCall);
              return null;
            });

        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);

        expect(
          log,
          contains(
            predicate<MethodCall>((call) {
              if (call.method != 'SystemChrome.setPreferredOrientations') {
                return false;
              }
              final args = call.arguments as List<dynamic>;
              return args.contains('DeviceOrientation.portraitUp') &&
                  args.contains('DeviceOrientation.portraitDown') &&
                  !args.contains('DeviceOrientation.landscapeLeft') &&
                  !args.contains('DeviceOrientation.landscapeRight');
            }),
          ),
        );
      },
    );

    test('AndroidManifest.xml configures MainActivity with portrait screenOrientation', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(
        manifestFile.existsSync(),
        isTrue,
        reason: 'AndroidManifest.xml should exist',
      );

      final content = manifestFile.readAsStringSync();
      expect(
        content.contains('android:screenOrientation="portrait"'),
        isTrue,
        reason: 'MainActivity must be locked to portrait natively in AndroidManifest.xml',
      );
    });
  });
}
