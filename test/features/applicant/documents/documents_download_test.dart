import 'dart:typed_data';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/api_error.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_model.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_files.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_access_policy.dart';

import 'documents_test_data.dart';
import 'documents_screen_harness.dart';
import 'documents_fonts.dart';

Future<void> download(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(Key('menu_$id')));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(PopupMenuItem<String>));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpDocumentFonts();
  testWidgets(
    'per-item download progress, duplicate prevention, save completion with same bytes',
    (tester) async {
      final item = DocumentDto.fromJson(documentJson());
      final repo = RepoDouble()
        ..items = [
          item,
          DocumentDto.fromJson(documentJson(id: 'other', name: 'Another.doc')),
        ]
        ..downloadPending = Completer<DownloadedDocument>();
      final files = FilesDouble();
      await pumpDocuments(tester, repo, files);
      await tester.pumpAndSettle();
      await download(tester, item.id);
      expect(repo.downloads, 1);
      expect(files.saves, 0);
      expect(find.text('Downloading…'), findsOneWidget);
      expect(
        tester
            .widget<PopupMenuButton<String>>(find.byKey(Key('menu_${item.id}')))
            .enabled,
        false,
      );
      expect(
        tester
            .widget<PopupMenuButton<String>>(
              find.byKey(const Key('menu_other')),
            )
            .enabled,
        true,
      );
      repo.downloadPending!.complete(
        DownloadedDocument(
          Uint8List.fromList([0, 255, 1]),
          'CV.docx',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ),
      );
      await tester.pumpAndSettle();
      expect(files.saves, 1);
      expect(files.saved!.bytes, [0, 255, 1]);
      expect(files.saved!.name, 'CV.docx');
      expect(find.textContaining('Saved to'), findsOneWidget);
    },
  );
  for (final state in ['cancel', 'failure', 'network']) {
    testWidgets('download $state never reports saved and supports retry', (
      tester,
    ) async {
      final item = DocumentDto.fromJson(documentJson());
      final repo = RepoDouble()..items = [item];
      final files = FilesDouble();
      if (state == 'cancel') files.location = null;
      if (state == 'failure') files.saveError = FileSystemException('test');
      if (state == 'network') {
        repo.downloadError = const ApiError(
          message: 'missing',
          statusCode: 404,
        );
      }
      await pumpDocuments(tester, repo, files);
      await tester.pumpAndSettle();
      await download(tester, item.id);
      await tester.pumpAndSettle();
      expect(find.textContaining('Saved to'), findsNothing);
      expect(files.saves, state == 'network' ? 0 : 1);
      if (state != 'cancel') {
        files.saveError = null;
        repo.downloadError = null;
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Saved to'), findsOneWidget);
      }
    });
  }
  testWidgets('SAF notRequired and destination cancellation skips GET', (
    tester,
  ) async {
    final repo = RepoDouble()..items = [DocumentDto.fromJson(documentJson())];
    final files = FilesDouble()..cancelDestination = true;
    final policy = PolicyDouble();
    await pumpDocuments(tester, repo, files, policy: policy);
    await tester.pumpAndSettle();
    await download(tester, repo.items.first.id);
    await tester.pumpAndSettle();
    expect(policy.requests, 0);
    expect(files.prepares, 1);
    expect(repo.downloads, 0);
    expect(files.saves, 0);
    expect(find.textContaining('Saved to'), findsNothing);
    expect(find.text('Save location selection cancelled.'), findsOneWidget);
  });
  testWidgets('one destination picker at a time and disposal skips GET', (
    tester,
  ) async {
    final repo = RepoDouble()
      ..items = [
        DocumentDto.fromJson(documentJson()),
        DocumentDto.fromJson(documentJson(id: 'other', name: 'Other.pdf')),
      ];
    final pending = Completer<DocumentDestination?>();
    final files = FilesDouble()..destinationPending = pending;
    await pumpDocuments(tester, repo, files, policy: PolicyDouble());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('menu_${repo.items.first.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuItem<String>));
    await tester.pump(const Duration(milliseconds: 400));
    expect(files.prepares, 1);
    tester
        .widget<PopupMenuButton<String>>(find.byKey(const Key('menu_other')))
        .onSelected!('download');
    await tester.pump(const Duration(milliseconds: 400));
    expect(files.prepares, 1);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    pending.complete(null);
    await tester.pumpAndSettle();
    expect(repo.downloads, 0);
  });
  testWidgets(
    'denied download skips GET; permanent block opens Settings only on tap',
    (tester) async {
      final repo = RepoDouble()..items = [DocumentDto.fromJson(documentJson())];
      final files = FilesDouble();
      final policy = PolicyDouble()
        ..download = const DocumentAccessDecision(DocumentAccessStatus.denied)
        ..requestResult = const DocumentAccessDecision(
          DocumentAccessStatus.denied,
        );
      await pumpDocuments(tester, repo, files, policy: policy);
      await tester.pumpAndSettle();
      await download(tester, repo.items.first.id);
      expect(repo.downloads, 0);
      expect(files.prepares, 0);
      expect(
        find.byKey(const Key('documents_permission_settings')),
        findsNothing,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      policy.download = const DocumentAccessDecision(
        DocumentAccessStatus.permanentlyDenied,
        settingsCanHelp: true,
      );
      await download(tester, repo.items.first.id);
      expect(policy.requests, 1);
      expect(policy.settings, 0);
      policy.settingsOpened = false;
      await tester.tap(find.byKey(const Key('documents_permission_settings')));
      await tester.pumpAndSettle();
      expect(policy.settings, 1);
      expect(find.textContaining("Open this app's settings"), findsOneWidget);
      expect(repo.downloads, 0);
    },
  );
  testWidgets('restricted and repeated resume do not transfer', (tester) async {
    final repo = RepoDouble()..items = [DocumentDto.fromJson(documentJson())];
    final files = FilesDouble();
    final policy = PolicyDouble()
      ..download = const DocumentAccessDecision(
        DocumentAccessStatus.restricted,
      );
    await pumpDocuments(tester, repo, files, policy: policy);
    await tester.pumpAndSettle();
    await download(tester, repo.items.first.id);
    expect(
      find.byKey(const Key('documents_permission_settings')),
      findsNothing,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repo.downloads, 0);
    expect(files.prepares, 0);
    expect(policy.settings, 0);
  });
  testWidgets(
    'Settings return rechecks grant without auto download; revocation on next tap',
    (tester) async {
      final repo = RepoDouble()..items = [DocumentDto.fromJson(documentJson())];
      final files = FilesDouble();
      final policy = PolicyDouble()
        ..download = const DocumentAccessDecision(
          DocumentAccessStatus.permanentlyDenied,
          settingsCanHelp: true,
        );
      await pumpDocuments(tester, repo, files, policy: policy);
      await tester.pumpAndSettle();
      await download(tester, repo.items.first.id);
      await tester.tap(find.byKey(const Key('documents_permission_settings')));
      await tester.pumpAndSettle();
      expect(policy.settings, 1);
      policy.download = const DocumentAccessDecision(
        DocumentAccessStatus.granted,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(repo.downloads, 0);
      expect(files.prepares, 0);
      await download(tester, repo.items.first.id);
      await tester.pumpAndSettle();
      expect(repo.downloads, 1);
      policy.download = const DocumentAccessDecision(
        DocumentAccessStatus.denied,
      );
      policy.requestResult = const DocumentAccessDecision(
        DocumentAccessStatus.denied,
      );
      await download(tester, repo.items.first.id);
      expect(repo.downloads, 1);
      expect(files.prepares, 1);
      expect(policy.requests, 1);
    },
  );
  testWidgets('Vietnamese permission dialog fits 360x800', (tester) async {
    final repo = RepoDouble()..items = [DocumentDto.fromJson(documentJson())];
    final policy = PolicyDouble()
      ..download = const DocumentAccessDecision(
        DocumentAccessStatus.permanentlyDenied,
        settingsCanHelp: true,
      );
    await pumpDocuments(
      tester,
      repo,
      FilesDouble(),
      policy: policy,
      locale: 'vi',
      size: const Size(360, 800),
    );
    await tester.pumpAndSettle();
    await download(tester, repo.items.first.id);
    expect(find.textContaining('Quyền truy cập tệp đã bị chặn'), findsWidgets);
    expect(find.text('Mở Cài đặt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
