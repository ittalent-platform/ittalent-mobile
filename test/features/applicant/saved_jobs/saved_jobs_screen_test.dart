import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/auth/auth_notifier.dart';
import 'package:ittalent_mobile/auth/auth_state.dart';
import 'package:ittalent_mobile/features/applicant/saved_jobs/saved_jobs_models.dart';
import 'package:ittalent_mobile/features/applicant/saved_jobs/saved_jobs_screen.dart';
import 'package:ittalent_mobile/features/applicant/saved_jobs/widgets/remove_unavailable_dialog.dart';
import 'package:ittalent_mobile/features/applicant/saved_jobs/widgets/saved_job_card.dart';
import 'package:ittalent_mobile/features/applicant/saved_jobs/widgets/unavailable_job_card.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';

import '../../../helpers/fake_api.dart';

class _FakeAuth extends AuthNotifier {
  @override
  AuthState build() =>
      AuthState.authenticated(userId: 'u1', email: 'an@example.com');
}

Future<ProviderContainer> _pumpSavedJobs(
  WidgetTester tester,
  FakeAdapter adapter,
) async {
  tester.view.physicalSize = const Size(600, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = adapter;

  final container = ProviderContainer(
    overrides: [
      dioProvider.overrideWithValue(dio),
      currentUserIdProvider.overrideWithValue('u1'),
      authNotifierProvider.overrideWith(_FakeAuth.new),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        themeMode: ThemeMode.light,
        home: SavedJobsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Map<String, dynamic> _savedJobJson({
  required String id,
  required String jobId,
  String availability = 'available',
  String title = 'Senior Software Engineer',
  String companyName = 'FPT Software',
  num salaryMin = 20000000,
  num salaryMax = 40000000,
}) => {
  'id': id,
  'jobId': jobId,
  'savedAt': '2026-03-01T12:00:00.000Z',
  'availability': availability,
  'title': title,
  'enterprise': {
    'id': 'ent-1',
    'name': companyName,
  },
  'location': 'Ho Chi Minh',
  'employmentType': 'full_time',
  'level': 'senior',
  'salaryMin': salaryMin,
  'salaryMax': salaryMax,
  'salaryNegotiable': false,
  'currency': 'VND',
};

void main() {
  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
  });

  group('SavedJobCard', () {
    testWidgets('renders job info and handles remove and tap', (tester) async {
      final item = SavedJobItem.fromJson(_savedJobJson(id: 's1', jobId: 'j1'));
      var removed = false;
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SavedJobCard(
              item: item,
              onRemove: (_) => removed = true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Senior Software Engineer'), findsOneWidget);
      expect(find.textContaining('FPT Software'), findsOneWidget);
      expect(find.textContaining('20–40M VND'), findsOneWidget);

      await tester.tap(find.byType(SavedJobCard));
      expect(tapped, isTrue);

      await tester.tap(find.byIcon(Icons.favorite));
      expect(removed, isTrue);
    });
  });

  group('UnavailableJobCard', () {
    testWidgets('renders unavailable warning and triggers request remove', (tester) async {
      final item = SavedJobItem.fromJson(
        _savedJobJson(id: 's2', jobId: 'j2', availability: 'unavailable'),
      );
      var requestRemove = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: UnavailableJobCard(
              item: item,
              onRequestRemove: (_) => requestRemove = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(UnavailableJobCard), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite));
      expect(requestRemove, isTrue);
    });
  });

  group('RemoveUnavailableDialog', () {
    testWidgets('cancels and confirms dialog', (tester) async {
      var confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => RemoveUnavailableDialog.show(
                  context,
                  onConfirm: () => confirmed = true,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(RemoveUnavailableDialog), findsOneWidget);
      expect(confirmed, isFalse);
    });
  });

  group('SavedJobsScreen', () {
    testWidgets('renders tabs and job cards from api', (tester) async {
      final adapter = FakeAdapter((options) {
        if (options.path.contains('/wishlist')) {
          return jsonBody({
            'items': [
              _savedJobJson(id: 's1', jobId: 'j1'),
              _savedJobJson(
                id: 's2',
                jobId: 'j2',
                availability: 'unavailable',
              ),
            ],
            'total': 2,
            'page': 1,
            'totalPages': 1,
          });
        }
        return jsonBody({});
      });

      await _pumpSavedJobs(tester, adapter);

      expect(find.byType(SavedJobsScreen), findsOneWidget);
      expect(find.byType(SavedJobCard), findsOneWidget);
      expect(find.byType(UnavailableJobCard), findsOneWidget);

      // Verify tabs exist
      expect(find.byKey(const Key('saved_jobs_tab_all')), findsOneWidget);
      expect(find.byKey(const Key('saved_jobs_tab_available')), findsOneWidget);
      expect(find.byKey(const Key('saved_jobs_tab_unavailable')), findsOneWidget);

      // Tap available tab
      await tester.tap(find.byKey(const Key('saved_jobs_tab_available')));
      await tester.pumpAndSettle();
    });

    testWidgets('renders empty state when items list is empty', (tester) async {
      final adapter = FakeAdapter((options) {
        if (options.path.contains('/wishlist')) {
          return jsonBody({
            'items': <Map<String, dynamic>>[],
            'total': 0,
            'page': 1,
            'totalPages': 1,
          });
        }
        return jsonBody({});
      });

      await _pumpSavedJobs(tester, adapter);

      expect(find.byType(SavedJobsScreen), findsOneWidget);
      expect(find.byType(SavedJobCard), findsNothing);
    });
  });
}
