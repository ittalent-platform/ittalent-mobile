import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_files.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_model.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_constants.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_repository.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_screen.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';
import 'package:ittalent_mobile/utils/double_brace_asset_loader.dart';

class _LocaleLoader extends AssetLoader {
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      DoubleBraceAssetLoader.convert(
        jsonDecode(
          File('assets/translations/${locale.languageCode}.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
      );
}

class _FilesDouble extends DocumentFiles {
  _FilesDouble(this.selection);

  SelectedDocument? selection;

  @override
  Future<SelectedDocument?> pick() async => selection;
}

class _RepositoryDouble extends DocumentsRepository {
  _RepositoryDouble() : super(ApiClient(dio: Dio()));

  List<DocumentDto> items = [];
  Completer<DocumentDto>? uploadPending;
  CancelToken? uploadCancel;

  @override
  Future<DocumentsPage> list(
    DocumentsQuery query,
    int page, {
    int limit = DocumentConstants.pageSize,
  }) async {
    final filtered = items
        .where(
          (item) =>
              (query.type == null || item.type == query.type) &&
              item.fileName.contains(query.search),
        )
        .toList();
    return DocumentsPage(
      items: filtered,
      page: page,
      limit: limit,
      total: filtered.length,
      totalPages: 1,
    );
  }

  @override
  Future<DocumentDto> upload(
    SelectedDocument file,
    DocumentType type, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    uploadCancel = cancelToken;
    onProgress?.call(1, 2);
    return uploadPending?.future ?? item(type: type);
  }
}

DocumentDto item({
  String id = 'document',
  DocumentType type = DocumentType.cv,
  bool isDefault = false,
}) => DocumentDto(
  id: id,
  ownerId: 'owner',
  type: type,
  fileName: type == DocumentType.cv ? 'CV.pdf' : 'Cover letter.pdf',
  mimeType: 'application/pdf',
  size: 125000,
  isDefault: isDefault,
  createdAt: DateTime.utc(2026, 10, 1),
);

SelectedDocument selectedPdf() => SelectedDocument(
  name: 'CV.pdf',
  size: 6,
  readBytes: () async => Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2d, 0]),
);

Future<void> _pumpDocuments(
  WidgetTester tester,
  _RepositoryDouble repository,
  _FilesDouble files,
) async {
  final container = ProviderContainer(
    overrides: [
      documentsRepositoryProvider.overrideWithValue(repository),
      documentFilesProvider.overrideWithValue(files),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('vi')],
        path: 'assets/translations',
        startLocale: const Locale('en'),
        saveLocale: false,
        assetLoader: _LocaleLoader(),
        child: Builder(
          builder: (context) => MaterialApp(
            theme: AppTheme.light,
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            home: const DocumentsScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openMenu(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(Key('menu_$id')));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
    final fontCache = Directory('build/documents-test-font-cache')
      ..createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => fontCache.absolute.path,
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
  });

  testWidgets('filters are direct chips and the list has no sort control', (
    tester,
  ) async {
    final repository = _RepositoryDouble()
      ..items = [item(), item(id: 'cover', type: DocumentType.coverLetter)];
    await _pumpDocuments(tester, repository, _FilesDouble(null));

    expect(find.byKey(const Key('documents_sort')), findsNothing);
    await tester.tap(find.byKey(const Key('filter_cover_letter')));
    await tester.pumpAndSettle();
    expect(find.text('Cover letter.pdf'), findsOneWidget);
    expect(find.text('CV.pdf'), findsNothing);
  });

  testWidgets('menu puts View first and only allows CV to become default', (
    tester,
  ) async {
    final repository = _RepositoryDouble()
      ..items = [item(), item(id: 'cover', type: DocumentType.coverLetter)];
    await _pumpDocuments(tester, repository, _FilesDouble(null));

    await openMenu(tester, 'document');
    final actions = find.byType(ListTile);
    expect(
      tester.widget<ListTile>(actions.first).key,
      const Key('documents_action_view'),
    );
    expect(
      find.byKey(const Key('documents_action_setDefault')),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await openMenu(tester, 'cover');
    expect(find.byKey(const Key('documents_action_setDefault')), findsNothing);
  });

  testWidgets(
    'delete sheet explains application snapshots and default impact',
    (tester) async {
      final repository = _RepositoryDouble()..items = [item(isDefault: true)];
      await _pumpDocuments(tester, repository, _FilesDouble(null));

      await openMenu(tester, 'document');
      await tester.tap(find.byKey(const Key('documents_action_delete')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Companies keep the copies'), findsOneWidget);
      expect(find.textContaining('default CV'), findsOneWidget);
    },
  );

  testWidgets('upload cancellation cancels its request token', (tester) async {
    final pending = Completer<DocumentDto>();
    final repository = _RepositoryDouble()..uploadPending = pending;
    await _pumpDocuments(tester, repository, _FilesDouble(selectedPdf()));

    await tester.tap(find.byKey(const Key('documents_upload')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pick_cv')));
    await tester.pump();
    expect(repository.uploadCancel, isNotNull);
    await tester.tap(find.byKey(const Key('documents_upload_cancel')));
    await tester.pumpAndSettle();
    expect(repository.uploadCancel!.isCancelled, isTrue);
    pending.complete(item());
  });
}
