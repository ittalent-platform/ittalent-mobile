import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void setUpDocumentFonts() {
  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
    final fontCache = Directory('build/documents-test-font-cache')
      ..createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => fontCache.absolute.path,
        );
    final fonts = jsonDecode(
      File('test/fixtures/fonts/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    GoogleFonts.config.httpClient = MockClient((request) async {
      final hash = request.url.pathSegments.last.replaceAll('.ttf', '');
      final name = fonts[hash] as String?;
      return name == null
          ? http.Response('', 404)
          : http.Response.bytes(
              File('test/fixtures/fonts/$name').readAsBytesSync(),
              200,
            );
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
    for (final weight in [
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
    ]) {
      GoogleFonts.instrumentSans(fontWeight: weight);
      GoogleFonts.spaceGrotesk(fontWeight: weight);
    }
    await GoogleFonts.pendingFonts();
    final fallback = FontLoader('InstrumentSans')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('test/fixtures/fonts/SpaceGrotesk-Regular.ttf')
                .readAsBytesSync(),
          ),
        ),
      );
    await fallback.load();
    final manifest = jsonDecode(
      await rootBundle.loadString('FontManifest.json'),
    ) as List<dynamic>;
    for (final font in manifest) {
      final loader = FontLoader(font['family'] as String);
      for (final asset in font['fonts'] as List<dynamic>) {
        loader.addFont(rootBundle.load(asset['asset'] as String));
      }
      await loader.load();
    }
  });
}
