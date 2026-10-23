import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/app/router.dart';
import 'package:ittalent_mobile/auth/auth_dto.dart';
import 'package:ittalent_mobile/auth/auth_notifier.dart';
import 'package:ittalent_mobile/auth/auth_state.dart';
import 'package:ittalent_mobile/config/routes.dart';
import 'package:ittalent_mobile/features/applicant/certificates/certificates_providers.dart';
import 'package:ittalent_mobile/features/applicant/documents/document_model.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_repository.dart';
import 'package:ittalent_mobile/features/applicant/documents/documents_screen.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';
import 'package:ittalent_mobile/utils/double_brace_asset_loader.dart';

import 'documents_test_data.dart';

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

class RepoDouble extends DocumentsRepository {
  RepoDouble() : super(ApiClient(dio: Dio()));
  int uploads = 0, lists = 0;
  Object? uploadError, listError;
  Completer<DocumentsPage>? listPending;
  List<DocumentDto> items = [];
  bool more = false;
  @override
  Future<DocumentsPage> list(DocumentsQuery q, int page) async {
    lists++;
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
      limit: 20,
      total: filtered.length,
      totalPages: more ? 2 : 1,
    );
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
  RepoDouble repo, {
  Size size = const Size(390, 844),
  String locale = 'en',
  bool router = false,
  bool authenticated = true,
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
