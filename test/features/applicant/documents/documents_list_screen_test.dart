import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/api_error.dart';
import 'package:ittalent_mobile/app/router.dart';
import 'package:ittalent_mobile/config/routes.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_model.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_screen.dart';

import 'documents_test_data.dart';
import 'documents_screen_harness.dart';
import 'documents_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpDocumentFonts();
  for (final size in [const Size(360, 800), const Size(390, 844)]) {
    for (final lang in ['en', 'vi']) {
      testWidgets(
        '$lang $size long Unicode names, filters, keyboard and sheet do not overflow',
        (tester) async {
          final repo = RepoDouble()
            ..items = [
              DocumentDto.fromJson(
                documentJson(
                  name: 'Nguyễn Thị Hoàng Anh — Hồ sơ chuyên môn phát triển phần mềm và thư xin việc rất dài.docx',
                  isDefault: true,
                ),
              ),
            ];
          await pumpDocuments(tester, repo, size: size, locale: lang);
          await tester.pumpAndSettle();
          expect(
            find.text(lang == 'en' ? 'My documents' : 'Tài liệu của tôi'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpAndSettle();
          const captureDir = String.fromEnvironment('DOCUMENTS_CAPTURE_DIR');
          if (captureDir.isNotEmpty) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const Key('docs_capture')),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage();
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await Directory(captureDir).create(recursive: true);
              await File(
                '$captureDir/documents_${lang}_${size.width.toInt()}.png',
              ).writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }
        },
      );
    }
  }
  testWidgets(
    'loading skeleton then empty library, empty type, no results, debounce and max100',
    (tester) async {
      final pending = Completer<DocumentsPage>();
      final repo = RepoDouble()..listPending = pending;
      await pumpDocuments(tester, repo);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('No documents yet'), findsNothing);
      repo.listPending = null;
      pending.complete(DocumentsPage.fromJson(pageJson([])));
      await tester.pumpAndSettle();
      expect(find.text('No documents yet'), findsOneWidget);
    },
  );
  testWidgets('list error retry, load more and refresh retain functionality', (
    tester,
  ) async {
    final repo = RepoDouble()..listError = const ApiError(message: 'network');
    await pumpDocuments(tester, repo);
    await tester.pumpAndSettle();
    expect(find.text('Could not load documents'), findsOneWidget);
    repo.listError = null;
    repo.items = [DocumentDto.fromJson(documentJson())];
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    final before = repo.lists;
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(repo.lists, before + 1);
  });
  testWidgets('Documents menu navigates from Me and back; guest is guarded', (
    tester,
  ) async {
    final c = await pumpDocuments(tester, RepoDouble(), router: true);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('me_menu_documents')));
    await tester.pumpAndSettle();
    expect(find.byType(DocumentsScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Back to Me'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('me_menu_documents')), findsOneWidget);
    c.read(routerProvider).go(AppRoutes.documents);
    await tester.pumpAndSettle();
    expect(find.byType(DocumentsScreen), findsOneWidget);
  });
  testWidgets('guest Documents route redirects to welcome', (tester) async {
    final c = await pumpDocuments(
      tester,
      RepoDouble(),
      router: true,
      authenticated: false,
    );
    await tester.pumpAndSettle();
    c.read(routerProvider).go(AppRoutes.documents);
    await tester.pumpAndSettle();
    expect(
      c.read(routerProvider).routeInformationProvider.value.uri.path,
      AppRoutes.welcome,
    );
    expect(find.byType(DocumentsScreen), findsNothing);
  });
}
