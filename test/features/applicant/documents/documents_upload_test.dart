import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/api_error.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_model.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_files.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_access_policy.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_providers.dart';

import 'documents_test_data.dart';
import 'documents_screen_harness.dart';
import 'documents_fonts.dart';
import 'documents_upload_data.dart';

Future<void> choose(WidgetTester tester, String type) async {
  await tester.tap(find.byKey(const Key('documents_upload')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('pick_$type')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpDocumentFonts();
  testWidgets('sheet cancellation and picker cancellation never upload', (
    tester,
  ) async {
    final repo = RepoDouble();
    final files = FilesDouble();
    await pumpDocuments(tester, repo, files);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('documents_upload')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(files.picks, 0);
    await choose(tester, 'cv');
    await tester.pumpAndSettle();
    expect(files.picks, 1);
    expect(repo.uploads, 0);
    expect(find.text('Could not upload document'), findsNothing);
  });
  for (final type in ['cv', 'cover_letter']) {
    testWidgets(
      'upload $type real progress, duplicate tap prevention and successful refresh',
      (tester) async {
        final repo = RepoDouble()..uploadPending = Completer<DocumentDto>();
        final files = FilesDouble()..selection = selected('docx');
        await pumpDocuments(tester, repo, files);
        await tester.pumpAndSettle();
        await choose(tester, type);
        expect(repo.uploads, 1);
        expect(repo.lastType!.value, type);
        expect(find.text('Uploading…'), findsOneWidget);
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator),
              )
              .value,
          0.4,
        );
        await tester.tap(find.byKey(const Key('documents_upload')));
        await tester.pump();
        expect(files.picks, 1);
        repo.uploadPending!.complete(
          DocumentDto.fromJson(documentJson(type: type)),
        );
        await tester.pumpAndSettle();
        expect(find.text('Document uploaded'), findsOneWidget);
        expect(find.text('Nguyễn Văn An.pdf'), findsOneWidget);
        expect(repo.lists, 2);
      },
    );
  }
  testWidgets(
    'validation shows choose again, failed upload retries without losing library',
    (tester) async {
      final repo = RepoDouble()..items = [DocumentDto.fromJson(documentJson())];
      final files = FilesDouble()..selection = selected('pdf', size: 0);
      await pumpDocuments(tester, repo, files);
      await tester.pumpAndSettle();
      await choose(tester, 'cv');
      await tester.pumpAndSettle();
      expect(repo.uploads, 0);
      expect(
        find.text('This file is empty. Choose another file.'),
        findsOneWidget,
      );
      expect(find.text('Nguyễn Văn An.pdf'), findsNWidgets(2));
      files.selection = selected('doc');
      repo.uploadError = const ApiError(message: 'fail', statusCode: 502);
      await tester.tap(find.text('Choose another file'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick_cover_letter')));
      await tester.pumpAndSettle();
      expect(repo.uploads, 1);
      expect(find.text('Nguyễn Văn An.pdf'), findsOneWidget);
      repo.uploadError = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(repo.uploads, 2);
      expect(repo.lastType, DocumentType.coverLetter);
    },
  );
  testWidgets(
    'revoked selected URI asks for reselection before another upload',
    (tester) async {
      final repo = RepoDouble()
        ..uploadError = const DocumentFileException(
          DocumentFileFailure.permissionDenied,
        );
      final files = FilesDouble()..selection = selected('pdf');
      await pumpDocuments(tester, repo, files, policy: PolicyDouble());
      await tester.pumpAndSettle();
      await choose(tester, 'cv');
      await tester.pumpAndSettle();
      expect(
        find.text('Access to the selected file was denied. Choose it again.'),
        findsOneWidget,
      );
      expect(find.text('Choose another file'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      repo.uploadError = null;
      await tester.tap(find.text('Choose another file'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pick_cv')));
      await tester.pumpAndSettle();
      expect(files.picks, 2);
      expect(repo.uploads, 2);
      expect(find.text('Document uploaded'), findsOneWidget);
    },
  );
  testWidgets(
    'upload success preserves current type filter and does not insert mismatched card',
    (tester) async {
      final repo = RepoDouble();
      final files = FilesDouble()..selection = selected('pdf');
      final c = await pumpDocuments(tester, repo, files);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('filter_cover_letter')));
      await tester.tap(find.byKey(const Key('filter_cover_letter')));
      await tester.pumpAndSettle();
      await choose(tester, 'cv');
      await tester.pumpAndSettle();
      expect(c.read(documentsQueryProvider).type, DocumentType.coverLetter);
      expect(find.text('Nguyễn Văn An.pdf'), findsNothing);
    },
  );
  testWidgets('denied upload blocks picker and POST; user retry can grant', (
    tester,
  ) async {
    final repo = RepoDouble();
    final files = FilesDouble()..selection = selected('pdf');
    final policy = PolicyDouble()
      ..upload = const DocumentAccessDecision(DocumentAccessStatus.denied)
      ..requestResult = const DocumentAccessDecision(
        DocumentAccessStatus.denied,
      );
    await pumpDocuments(tester, repo, files, policy: policy);
    await tester.pumpAndSettle();
    await choose(tester, 'cv');
    expect(files.picks, 0);
    expect(repo.uploads, 0);
    expect(policy.requests, 1);
    expect(
      find.text(
        'File access has not been granted. Upload is currently unavailable.',
      ),
      findsWidgets,
    );
    policy.requestResult = const DocumentAccessDecision(
      DocumentAccessStatus.granted,
    );
    await tester.tap(find.byKey(const Key('documents_permission_retry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pick_cv')));
    await tester.pumpAndSettle();
    expect(policy.requests, 2);
    expect(files.picks, 1);
    expect(repo.uploads, 1);
  });
  testWidgets(
    'Settings return rechecks grant without auto upload; revocation on next tap',
    (tester) async {
      final repo = RepoDouble()..items = [DocumentDto.fromJson(documentJson())];
      final files = FilesDouble()..selection = selected('pdf');
      final policy = PolicyDouble()
        ..upload = const DocumentAccessDecision(
          DocumentAccessStatus.permanentlyDenied,
          settingsCanHelp: true,
        );
      await pumpDocuments(tester, repo, files, policy: policy);
      await tester.pumpAndSettle();
      await choose(tester, 'cv');
      await tester.tap(find.byKey(const Key('documents_permission_settings')));
      await tester.pumpAndSettle();
      expect(policy.settings, 1);
      policy.upload = const DocumentAccessDecision(
        DocumentAccessStatus.granted,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(repo.uploads, 0);
      expect(files.picks, 0);
      await choose(tester, 'cv');
      await tester.pumpAndSettle();
      expect(repo.uploads, 1);
      policy.upload = const DocumentAccessDecision(DocumentAccessStatus.denied);
      policy.requestResult = const DocumentAccessDecision(
        DocumentAccessStatus.denied,
      );
      await choose(tester, 'cv');
      expect(repo.uploads, 1);
      expect(files.picks, 1);
      expect(policy.requests, 1);
    },
  );
}
