import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_files.dart';

/// Real Android system dialogs; drive with tool/documents_native_dialogs.py.
/// No backend, account, auth override, or mocked file plugin participates.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native save, pick bytes, duplicate name, cancel picker and save',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Documents native file test')),
          ),
        ),
      );
      final bytes = Uint8List.fromList(
        utf8.encode(
          '%PDF-1.4\n% Mobile Documents native fixture, no personal data\n%%EOF\n',
        ),
      );
      final files = DocumentFiles();
      const name = 'mobile_documents_native_probe_20261022.pdf';
      debugPrint('NATIVE_PHASE save');
      final first = await files.save(
        DownloadedDocument(bytes, name, 'application/pdf'),
      );
      expect(first, isNotNull);
      debugPrint('NATIVE_PHASE pick');
      final picked = await files.pick();
      expect(picked, isNotNull);
      expect(picked!.name, name);
      expect(await picked.readBytes(), bytes);
      debugPrint('NATIVE_PHASE duplicate');
      final duplicate = await files.save(
        DownloadedDocument(bytes, name, 'application/pdf'),
      );
      expect(duplicate, isNotNull);
      debugPrint('NATIVE_PHASE cancel_pick');
      expect(await files.pick(), isNull);
      debugPrint('NATIVE_PHASE cancel_save');
      expect(
        await files.save(
          DownloadedDocument(
            bytes,
            'mobile_documents_cancelled.pdf',
            'application/pdf',
          ),
        ),
        isNull,
      );
      binding.reportData = {
        'firstUri': first.toString(),
        'duplicateUri': duplicate.toString(),
        'bytes': bytes.length,
      };
      debugPrint('NATIVE_FILES_PASS');
    },
  );
}
