import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_files.dart';

/// Real Android ACTION_CREATE_DOCUMENT before bytes/HTTP, then URI write.
/// Drive the OS dialogs with tool/documents_native_dialogs.py --test ...
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native destination before transfer, URI write, pick and cancel',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Documents destination test')),
        ),
      );
      final bytes = Uint8List.fromList(
        utf8.encode(
          '%PDF-1.4\n% Mobile Documents native fixture, no personal data\n%%EOF\n',
        ),
      );
      final files = DocumentFiles();
      const name = 'mobile_documents_native_probe_20261022.pdf';
      const mime = 'application/pdf';
      debugPrint('NATIVE_PHASE save');
      final destination = await files.prepareDownload(name, mime);
      expect(destination, isNotNull);
      debugPrint('NATIVE_PHASE write');
      final uri = await destination!.write(
        DownloadedDocument(bytes, name, mime),
      );
      expect(uri?.scheme, 'content');
      await destination.abort(); // Committed destinations must survive abort.
      debugPrint('NATIVE_PHASE pick');
      final selected = await files.pick();
      expect(selected, isNotNull);
      expect(selected!.name, name);
      expect(await selected.readBytes(), bytes);
      debugPrint('NATIVE_PHASE duplicate');
      final second = await files.prepareDownload(name, mime);
      expect(second, isNotNull);
      expect(
        await second!.write(DownloadedDocument(bytes, name, mime)),
        isNotNull,
      );
      await second.abort();
      debugPrint('NATIVE_PHASE cancel_pick');
      expect(await files.pick(), isNull);
      debugPrint('NATIVE_PHASE cancel_save');
      expect(
        await files.prepareDownload('mobile_documents_cancelled.pdf', mime),
        isNull,
      );
      binding.reportData = {'uri': uri.toString(), 'bytes': bytes.length};
      debugPrint('NATIVE_FILES_PASS');
    },
  );
}
