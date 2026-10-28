import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/api_error.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/app/router.dart';
import 'package:ittalent_mobile/auth/auth_dto.dart';
import 'package:ittalent_mobile/auth/auth_notifier.dart';
import 'package:ittalent_mobile/auth/auth_state.dart';
import 'package:ittalent_mobile/config/routes.dart';
import 'package:ittalent_mobile/features/applicant/certificates/certificates_providers.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_files.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_access_policy.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_model.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_constants.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_providers.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_repository.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_screen.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';
import 'package:ittalent_mobile/utils/double_brace_asset_loader.dart';

import 'documents_repository_test.dart' show documentJson, pageJson, selected;

class LocaleLoader extends AssetLoader {
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      DoubleBraceAssetLoader.convert(
        jsonDecode(
          File('assets/translations/${locale.languageCode}.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
      );
}

class FilesDouble extends DocumentFiles {
  SelectedDocument? selection;
  int picks = 0, saves = 0, prepares = 0, aborts = 0;
  bool cancelDestination = false;
  Completer<DocumentDestination?>? destinationPending;
  Uri? location = Uri.parse('file:///Downloads/Nguyen.pdf');
  Object? saveError;
  DownloadedDocument? saved;
  @override
  Future<SelectedDocument?> pick() async {
    picks++;
    return selection;
  }

  @override
  Future<Uri?> save(DownloadedDocument file) async {
    saves++;
    saved = file;
    if (saveError != null) throw saveError!;
    return location;
  }

  @override
  Future<DocumentDestination?> prepareDownload(
    String name,
    String mimeType,
  ) async {
    prepares++;
    if (destinationPending != null) return destinationPending!.future;
    if (cancelDestination) return null;
    return _FilesDestination(this);
  }
}

class _FilesDestination implements DocumentDestination {
  _FilesDestination(this.files);
  final FilesDouble files;
  @override
  Future<Uri?> write(DownloadedDocument file) => files.save(file);
  @override
  Future<void> abort() async => files.aborts++;
}

class PolicyDouble extends DocumentAccessPolicy {
  DocumentAccessDecision upload = const DocumentAccessDecision(
    DocumentAccessStatus.notRequired,
  );
  DocumentAccessDecision download = const DocumentAccessDecision(
    DocumentAccessStatus.notRequired,
  );
  DocumentAccessDecision? requestResult;
  bool settingsOpened = true;
  Completer<DocumentAccessDecision>? checkPending;
  int checks = 0, requests = 0, settings = 0;
  @override
  Future<DocumentAccessDecision> check(
    DocumentAccessOperation operation,
  ) async {
    checks++;
    if (checkPending != null) return checkPending!.future;
    return operation == DocumentAccessOperation.uploadRead ? upload : download;
  }

  @override
  Future<DocumentAccessDecision> request(
    DocumentAccessOperation operation,
  ) async {
    requests++;
    return requestResult ?? await check(operation);
  }

  @override
  Future<bool> openSettings() async {
    settings++;
    return settingsOpened;
  }
}

class RepoDouble extends DocumentsRepository {
  RepoDouble() : super(ApiClient(dio: Dio()));
  int uploads = 0,
      downloads = 0,
      defaults = 0,
      deletes = 0,
      lists = 0,
      countRequests = 0;
  DocumentType? lastType;
  DocumentsQuery? lastQuery;
  Object? uploadError,
      downloadError,
      defaultError,
      deleteError,
      listError,
      countError;
  Completer<DocumentDto>? uploadPending;
  Completer<DownloadedDocument>? downloadPending;
  Completer<DocumentsPage>? listPending;
  List<DocumentDto> items = [];
  bool more = false;
  @override
  Future<DocumentsPage> list(
    DocumentsQuery q,
    int page, {
    int limit = DocumentConstants.pageSize,
  }) async {
    lists++;
    lastQuery = q;
    if (limit == DocumentConstants.countPageSize) {
      countRequests++;
      if (countError != null) throw countError!;
    }
    if (listError != null) throw listError!;
    if (listPending != null) return listPending!.future;
    final filtered = items
        .where(
          (e) =>
              (q.type == null || e.type == q.type) &&
              e.fileName.contains(q.search),
        )
        .toList();
    return DocumentsPage(
      items: page == 1
          ? filtered
          : [DocumentDto.fromJson(documentJson(id: 'next'))],
      page: page,
      limit: limit,
      total: filtered.length,
      totalPages: more ? 2 : 1,
    );
  }

  @override
  Future<DocumentDto> upload(
    SelectedDocument file,
    DocumentType type, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    file.validate();
    uploads++;
    lastType = type;
    onProgress?.call(4, 10);
    if (uploadError != null) throw uploadError!;
    final item = uploadPending == null
        ? DocumentDto.fromJson(documentJson(type: type.value))
        : await uploadPending!.future;
    items = [item, ...items];
    return item;
  }

  @override
  Future<DownloadedDocument> download(
    DocumentDto item, {
    CancelToken? cancelToken,
    ProgressCallback? onProgress,
  }) async {
    downloads++;
    onProgress?.call(2, -1);
    if (downloadError != null) throw downloadError!;
    return downloadPending == null
        ? DownloadedDocument(
            Uint8List.fromList([1, 2, 255]),
            item.fileName,
            item.mimeType,
          )
        : downloadPending!.future;
  }

  @override
  Future<DocumentDto> setDefault(String id) async {
    defaults++;
    if (defaultError != null) throw defaultError!;
    items = [
      for (final item in items)
        DocumentDto(
          id: item.id,
          ownerId: item.ownerId,
          type: item.type,
          fileName: item.fileName,
          mimeType: item.mimeType,
          size: item.size,
          isDefault: item.id == id,
          createdAt: item.createdAt,
        ),
    ];
    return items.firstWhere((item) => item.id == id);
  }

  @override
  Future<void> delete(String id) async {
    deletes++;
    if (deleteError != null) throw deleteError!;
    items = items.where((item) => item.id != id).toList();
  }
}

class TestAuth extends AuthNotifier {
  TestAuth(this.initial);
  final AuthState initial;
  @override
  AuthState build() => initial;
}

Future<ProviderContainer> pumpDocuments(
  WidgetTester tester,
  RepoDouble repo,
  FilesDouble files, {
  Size size = const Size(390, 844),
  String locale = 'en',
  bool router = false,
  bool authenticated = true,
  PolicyDouble? policy,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final c = ProviderContainer(
    overrides: [
      documentsRepositoryProvider.overrideWithValue(repo),
      documentFilesProvider.overrideWithValue(files),
      if (policy != null)
        documentAccessPolicyProvider.overrideWithValue(policy),
      certificateCountProvider.overrideWith((ref) async => 0),
      authNotifierProvider.overrideWith(
        () => TestAuth(
          authenticated
              ? AuthState.authenticated(
                  user: const UserDTO(
                    id: 'test-user',
                    email: 'documents@example.test',
                    username: 'test',
                    role: 'user',
                  ),
                )
              : AuthState.unauthenticated(),
        ),
      ),
    ],
  );
  addTearDown(c.dispose);
  if (router) c.read(routerProvider).go(AppRoutes.profile);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: EasyLocalization(
        key: UniqueKey(),
        supportedLocales: const [Locale('en'), Locale('vi')],
        path: 'assets/translations',
        startLocale: Locale(locale),
        saveLocale: false,
        assetLoader: LocaleLoader(),
        child: Builder(
          builder: (context) => router
              ? MaterialApp.router(
                  theme: AppTheme.light,
                  routerConfig: c.read(routerProvider),
                  locale: context.locale,
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                )
              : MaterialApp(
                  theme: AppTheme.light,
                  locale: context.locale,
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  home: const RepaintBoundary(
                    key: Key('docs_capture'),
                    child: DocumentsScreen(),
                  ),
                ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return c;
}

Future<void> choose(WidgetTester tester, String type) async {
  await tester.tap(find.byKey(const Key('documents_upload')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('pick_$type')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> download(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(Key('menu_$id')));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Download'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
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
          await pumpDocuments(
            tester,
            repo,
            FilesDouble(),
            size: size,
            locale: lang,
          );
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
          await tester.tap(find.byType(TextField));
          tester.view.viewInsets = FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          tester.view.resetViewInsets();
          await tester.tap(find.byKey(const Key('documents_upload')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('pick_cover_letter')), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.text(lang == 'en' ? 'Cancel' : 'Hủy'));
          await tester.pumpAndSettle();
        },
      );
    }
  }
  testWidgets(
    'loading skeleton then empty library, empty type, no results, debounce and max100',
    (tester) async {
      final pending = Completer<DocumentsPage>();
      final repo = RepoDouble()..listPending = pending;
      final c = await pumpDocuments(tester, repo, FilesDouble());
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('No documents yet'), findsNothing);
      repo.listPending = null;
      pending.complete(DocumentsPage.fromJson(pageJson([])));
      await tester.pumpAndSettle();
      expect(find.text('No documents yet'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('filter_cv')));
      await tester.tap(find.byKey(const Key('filter_cv')));
      await tester.pumpAndSettle();
      expect(find.text('No files of this type yet'), findsOneWidget);
      final before = repo.lists;
      await tester.enterText(find.byType(TextField), '  Nguyễn  ');
      await tester.pump(const Duration(milliseconds: 299));
      expect(repo.lists, before);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(c.read(documentsQueryProvider).search, 'Nguyễn');
      expect(find.text('No matching documents'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'a' * 130);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(c.read(documentsQueryProvider).search.length, 100);
    },
  );
  testWidgets('list error retry, load more and refresh retain functionality', (
    tester,
  ) async {
    final repo = RepoDouble()..listError = const ApiError(message: 'network');
    await pumpDocuments(tester, repo, FilesDouble());
    await tester.pumpAndSettle();
    expect(find.text('Could not load documents'), findsOneWidget);
    repo.listError = null;
    repo.items = [DocumentDto.fromJson(documentJson())];
    repo.more = true;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('documents_more')));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Văn An.pdf'), findsNWidgets(2));
    final before = repo.lists;
    final countRequestsBefore = repo.countRequests;
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(repo.lists, greaterThan(before));
    expect(repo.countRequests, countRequestsBefore + 3);
  });
  testWidgets('sort applies once, resets the list query, and formats sizes', (
    tester,
  ) async {
    final repo = RepoDouble()..items = [DocumentDto.fromJson(documentJson())];
    final c = await pumpDocuments(tester, repo, FilesDouble());
    await tester.pumpAndSettle();
    expect(find.textContaining('342 KB'), findsOneWidget);
    expect(formatDocumentSize(0), '0 B');
    expect(formatDocumentSize(512), '512 B');
    expect(formatDocumentSize(1229), '1.2 KB');
    expect(formatDocumentSize(3670016), '3.5 MB');
    await tester.tap(find.byKey(const Key('documents_sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('File size'));
    await tester.tap(find.text('Ascending'));
    await tester.tap(find.byKey(const Key('documents_sort_apply')));
    await tester.pumpAndSettle();
    expect(c.read(documentsQueryProvider).sortField, DocumentSortField.size);
    expect(
      c.read(documentsQueryProvider).sortOrder,
      DocumentSortOrder.ascending,
    );
    expect(repo.lastQuery!.parameters(1)['sort_by'], 'size');
    expect(repo.lastQuery!.parameters(1)['sort_order'], 'asc');
  });

  testWidgets(
    'document actions set default and delete only after confirmation',
    (tester) async {
      final original = DocumentDto.fromJson(documentJson(id: 'old'));
      final target = DocumentDto.fromJson(
        documentJson(id: 'new', name: 'New.pdf'),
      );
      final repo = RepoDouble()..items = [original, target];
      await pumpDocuments(tester, repo, FilesDouble());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('menu_old')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Set Nguyễn Văn An.pdf as default'),
        findsOneWidget,
      );
      await tester.tap(find.textContaining('Set Nguyễn Văn An.pdf as default'));
      await tester.pumpAndSettle();
      expect(repo.defaults, 1);
      await tester.tap(find.byKey(const Key('menu_new')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Delete New.pdf'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.deletes, 0);
      await tester.tap(find.byKey(const Key('menu_new')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Delete New.pdf'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete document'));
      await tester.pumpAndSettle();
      expect(repo.deletes, 1);
    },
  );

  testWidgets('delete conflict keeps the document and reports why', (
    tester,
  ) async {
    final item = DocumentDto.fromJson(documentJson(id: 'used'));
    final repo = RepoDouble()
      ..items = [item]
      ..deleteError = const ApiError(message: 'in use', statusCode: 409);
    await pumpDocuments(tester, repo, FilesDouble());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu_used')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Delete Nguyễn Văn An.pdf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete document'));
    await tester.pumpAndSettle();
    expect(repo.deletes, 1);
    expect(find.text('Nguyễn Văn An.pdf'), findsOneWidget);
    expect(find.textContaining('used by an application'), findsOneWidget);
  });
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
        final countRequestsBefore = repo.countRequests;
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
        expect(repo.countRequests, countRequestsBefore + 3);
      },
    );
  }
  testWidgets(
    'filter chips show search-aware counts without blocking the list',
    (tester) async {
      final repo = RepoDouble()
        ..items = [
          DocumentDto.fromJson(
            documentJson(id: 'cv', type: 'cv', name: 'cv.pdf'),
          ),
          DocumentDto.fromJson(
            documentJson(id: 'cover', type: 'cover_letter', name: 'cover.pdf'),
          ),
        ];
      await pumpDocuments(tester, repo, FilesDouble());
      await tester.pumpAndSettle();
      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('CVs (1)', skipOffstage: false), findsOneWidget);
      expect(
        find.text('Cover letters (1)', skipOffstage: false),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'cover');
      await tester.pump(DocumentConstants.debounce);
      await tester.pumpAndSettle();
      expect(find.text('All (1)'), findsOneWidget);
      expect(find.text('CVs (0)', skipOffstage: false), findsOneWidget);
      expect(
        find.text('Cover letters (1)', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('cover.pdf'), findsOneWidget);
    },
  );
  testWidgets('count errors leave the document list usable', (tester) async {
    final repo = RepoDouble()
      ..items = [DocumentDto.fromJson(documentJson())]
      ..countError = const ApiError(message: 'count failed');
    await pumpDocuments(tester, repo, FilesDouble());
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Văn An.pdf'), findsOneWidget);
    expect(find.text('All (—)'), findsOneWidget);
  });
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
  testWidgets('Documents menu navigates from Me and back; guest is guarded', (
    tester,
  ) async {
    final c = await pumpDocuments(
      tester,
      RepoDouble(),
      FilesDouble(),
      router: true,
    );
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
      FilesDouble(),
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
    await tester.tap(find.textContaining('Download'));
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
