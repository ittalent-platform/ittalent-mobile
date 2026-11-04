import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/auth/auth_notifier.dart';
import 'package:ittalent_mobile/auth/auth_state.dart';
import 'package:ittalent_mobile/components/common/app_error_state.dart';
import 'package:ittalent_mobile/config/routes.dart';
import 'package:ittalent_mobile/features/applicant/jobs/job_detail_screen.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';

import '../../helpers/fake_api.dart';

class _FakeAuth extends AuthNotifier {
  _FakeAuth(this._state);

  final AuthState _state;

  @override
  AuthState build() => _state;
}

String _daysAhead(int days) =>
    DateTime.now().add(Duration(days: days)).toUtc().toIso8601String();

Map<String, dynamic> _job({
  String title = 'Senior Backend Engineer (Go)',
  String? expiresAt,
  String? description = 'Build the payment rails.',
  String? requirements = 'Go\nPostgreSQL',
  String? benefits = 'Health insurance',
}) => {
  'id': 'j1',
  'enterpriseId': 'e1',
  'enterprise': {'id': 'e1', 'name': 'Nimbus Pay'},
  'title': title,
  'location': 'Ha Noi',
  'employmentType': 'Full-time',
  'level': 'Senior',
  'salaryMin': 45000000,
  'salaryMax': 60000000,
  'salaryNegotiable': false,
  'currency': 'VND',
  'openings': 2,
  'description': description,
  'requirements': requirements,
  'benefits': benefits,
  'createdAt': DateTime.now()
      .subtract(const Duration(days: 3))
      .toUtc()
      .toIso8601String(),
  'expiresAt': expiresAt ?? _daysAhead(20),
};

const _company = {
  'id': 'e1',
  'name': 'Nimbus Pay',
  'industry': 'Fintech',
  'companySize': '51-200',
  'openRoleCount': 8,
};

/// The API of the job page: the job, its company and the applicant's own
/// applications to it.
FakeAdapter _adapter({
  ResponseBody Function(RequestOptions options)? job,
  List<Map<String, dynamic>> applications = const [],
  bool saved = false,
  ResponseBody Function(RequestOptions options)? wishlist,
}) => FakeAdapter((options) {
  final path = options.path;
  if (path == '/api/v1/job-postings/j1/public') {
    return (job ?? (_) => jsonBody(_job()))(options);
  }
  if (path == '/api/v1/enterprises/e1/public') return jsonBody(_company);
  // The saved jobs: read (GET), save (POST) and remove (DELETE).
  if (path == '/api/v1/me/wishlist/jobs/j1' && options.method == 'GET') {
    return jsonBody({'isSaved': saved, 'wishlistId': saved ? 'w1' : null});
  }
  if (path == '/api/v1/me/wishlist' || path == '/api/v1/me/wishlist/jobs/j1') {
    return (wishlist ??
        (o) => o.method == 'POST'
            ? jsonBody({'saved': true, 'message': 'Saved'}, status: 201)
            : jsonBody({'removed': true, 'message': 'Removed'}))(options);
  }
  if (path == '/api/v1/me/applications') {
    return jsonBody({'items': applications, 'total': applications.length});
  }
  throw StateError('Unexpected request to $path');
});

Future<void> _pump(
  WidgetTester tester,
  FakeAdapter adapter, {
  AuthState? auth,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
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
      authNotifierProvider.overrideWith(
        () => _FakeAuth(auth ?? AuthState.unauthenticated()),
      ),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: AppRoutes.jobDetail('j1'),
    routes: [
      GoRoute(
        path: AppRoutes.jobs,
        builder: (context, state) => const Scaffold(body: Text('jobs page')),
      ),
      GoRoute(
        path: '${AppRoutes.jobs}/:id',
        builder: (context, state) =>
            JobDetailScreen(jobId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'apply',
            builder: (context, state) => Scaffold(
              body: Text('apply page ${state.pathParameters['id']}'),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => Scaffold(
          body: Text('login page from ${state.uri.queryParameters['from']}'),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.companies}/:id',
        builder: (context, state) =>
            Scaffold(body: Text('company page ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '${AppRoutes.myApplications}/:id',
        builder: (context, state) => Scaffold(
          body: Text('application page ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

final _signedIn = AuthState.authenticated(userId: 'u1');

/// A Text, plain or made of spans, whose text holds [part].
Finder _textWith(String part) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data ?? widget.textSpan?.toPlainText() ?? '').contains(part),
);

void main() {
  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
  });

  group('JobDetailScreen', () {
    for (final size in const [Size(360, 800), Size(390, 844)]) {
      testWidgets('shows the whole job without overflow at ${size.width}px', (
        tester,
      ) async {
        await _pump(
          tester,
          _adapter(
            job: (_) => jsonBody(
              _job(
                title: 'Principal Full-Stack TypeScript Engineer, Payments Platform',
              ),
            ),
          ),
          size: size,
        );

        expect(
          find.text(
            'Principal Full-Stack TypeScript Engineer, Payments Platform',
          ),
          findsOneWidget,
        );
        expect(_textWith('45–60M'), findsOneWidget);
        expect(find.text('Build the payment rails.'), findsOneWidget);
        expect(find.text('jobs.detail.requirements'), findsOneWidget);
        expect(find.text('Health insurance'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('shows the company under the job, once it is loaded', (
      tester,
    ) async {
      await _pump(tester, _adapter());

      // The name is a link under the title and the title of the company card.
      expect(find.text('Nimbus Pay'), findsNWidgets(2));
      expect(find.textContaining('Fintech'), findsWidgets);
    });

    testWidgets('a guest signs in to apply, without asking for applications', (
      tester,
    ) async {
      final adapter = _adapter();
      await _pump(tester, adapter);

      expect(find.text('jobs.detail.signInToApply'), findsOneWidget);
      expect(
        adapter.requests.where((r) => r.path == '/api/v1/me/applications'),
        isEmpty,
      );

      await tester.tap(find.text('jobs.detail.signInToApply'));
      await tester.pumpAndSettle();
      // The login page knows where to bring the applicant back to.
      expect(find.text('login page from /jobs/j1/apply'), findsOneWidget);
    });

    group('the bookmark of the bar', () {
      List<RequestOptions> wishlistCalls(FakeAdapter adapter) => [
        for (final r in adapter.requests)
          if (r.path.startsWith('/api/v1/me/wishlist')) r,
      ];

      testWidgets('a guest is sent to sign in, and brought back here', (
        tester,
      ) async {
        final adapter = _adapter();
        await _pump(tester, adapter);

        await tester.tap(find.byTooltip('jobs.detail.save'));
        await tester.pumpAndSettle();

        expect(find.text('login page from /jobs/j1'), findsOneWidget);
        expect(wishlistCalls(adapter), isEmpty);
      });

      testWidgets('an applicant saves the job, and is told so', (tester) async {
        final adapter = _adapter();
        await _pump(tester, adapter, auth: _signedIn);
        expect(find.byTooltip('jobs.detail.save'), findsOneWidget);

        await tester.tap(find.byTooltip('jobs.detail.save'));
        await tester.pumpAndSettle();

        final post = wishlistCalls(adapter)
            .singleWhere((r) => r.method == 'POST');
        expect(post.path, '/api/v1/me/wishlist');
        expect(post.data, {'jobId': 'j1'});
        expect(find.text('jobs.detail.saved'), findsOneWidget);
        expect(find.byTooltip('jobs.detail.unsave'), findsOneWidget);
        expect(find.byTooltip('jobs.detail.save'), findsNothing);
      });

      testWidgets('a saved job shows so, and a tap takes it out', (
        tester,
      ) async {
        final adapter = _adapter(saved: true);
        await _pump(tester, adapter, auth: _signedIn);
        expect(find.byTooltip('jobs.detail.unsave'), findsOneWidget);

        await tester.tap(find.byTooltip('jobs.detail.unsave'));
        await tester.pumpAndSettle();

        final delete = wishlistCalls(adapter)
            .singleWhere((r) => r.method == 'DELETE');
        expect(delete.path, '/api/v1/me/wishlist/jobs/j1');
        expect(find.text('jobs.detail.unsaved'), findsOneWidget);
        expect(find.byTooltip('jobs.detail.save'), findsOneWidget);
      });

      testWidgets('a failure says so and leaves the bookmark as it was', (
        tester,
      ) async {
        await _pump(
          tester,
          _adapter(wishlist: (_) => jsonBody({'message': 'Boom'}, status: 500)),
          auth: _signedIn,
        );

        await tester.tap(find.byTooltip('jobs.detail.save'));
        await tester.pumpAndSettle();

        expect(find.text('jobs.detail.saveFailed'), findsOneWidget);
        expect(find.byTooltip('jobs.detail.save'), findsOneWidget);
      });

      testWidgets('a closed job cannot be saved any more', (tester) async {
        final closed = _job(expiresAt: _daysAhead(-2));
        await _pump(
          tester,
          _adapter(job: (_) => jsonBody(closed)),
          auth: _signedIn,
        );

        expect(find.byTooltip('jobs.detail.save'), findsNothing);
        expect(find.byTooltip('jobs.detail.unsave'), findsNothing);
      });

      testWidgets('a closed job that was saved can still be taken out', (
        tester,
      ) async {
        final closed = _job(expiresAt: _daysAhead(-2));
        await _pump(
          tester,
          _adapter(job: (_) => jsonBody(closed), saved: true),
          auth: _signedIn,
        );

        expect(find.byTooltip('jobs.detail.unsave'), findsOneWidget);
      });

      testWidgets('fits a 360px screen beside the longest button', (
        tester,
      ) async {
        await _pump(
          tester,
          _adapter(applications: const []),
          auth: _signedIn,
          size: const Size(360, 800),
        );

        expect(find.byTooltip('jobs.detail.save'), findsOneWidget);
        expect(find.text('jobs.detail.apply'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('an applicant applies from the bar', (tester) async {
      await _pump(tester, _adapter(), auth: _signedIn);

      expect(find.text('jobs.detail.apply'), findsOneWidget);
      await tester.tap(find.text('jobs.detail.apply'));
      await tester.pumpAndSettle();

      expect(find.text('apply page j1'), findsOneWidget);
    });

    testWidgets('an applicant who applied goes to their application', (
      tester,
    ) async {
      await _pump(
        tester,
        _adapter(
          applications: [
            {'id': 'a1', 'status': 'pending', 'canApplyAgain': false},
          ],
        ),
        auth: _signedIn,
      );

      expect(find.text('jobs.detail.apply'), findsNothing);
      expect(find.text('jobs.detail.applied'), findsOneWidget);

      await tester.tap(find.text('jobs.detail.applied'));
      await tester.pumpAndSettle();
      expect(find.text('application page a1'), findsOneWidget);
    });

    testWidgets('a closed application that may be redone offers to apply', (
      tester,
    ) async {
      await _pump(
        tester,
        _adapter(
          applications: [
            {'id': 'a1', 'status': 'withdrawn', 'canApplyAgain': true},
          ],
        ),
        auth: _signedIn,
      );

      expect(find.text('jobs.detail.apply'), findsOneWidget);
      expect(find.text('jobs.detail.applied'), findsNothing);
    });

    testWidgets('a job past its deadline has no Apply button', (tester) async {
      await _pump(
        tester,
        _adapter(
          job: (_) => jsonBody(
            _job(
              expiresAt: DateTime.now()
                  .subtract(const Duration(days: 1))
                  .toUtc()
                  .toIso8601String(),
            ),
          ),
        ),
        auth: _signedIn,
      );

      expect(find.text('jobs.detail.apply'), findsNothing);
      expect(find.text('jobs.detail.seeSimilar'), findsOneWidget);

      await tester.tap(find.text('jobs.detail.seeSimilar'));
      await tester.pumpAndSettle();
      expect(find.text('jobs page'), findsOneWidget);
    });

    testWidgets('the company card opens the company', (tester) async {
      await _pump(tester, _adapter());

      final card = find.text('Nimbus Pay').last;
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(find.text('company page e1'), findsOneWidget);
    });

    testWidgets('Share copies the link of the job', (tester) async {
      // A test has no platform clipboard, so a stand-in takes the text.
      String? copied;
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          copied = arguments['text'] as String?;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await _pump(tester, _adapter());

      await tester.tap(find.byTooltip('jobs.detail.share'));
      await tester.pumpAndSettle();

      expect(copied, endsWith('/career/j1'));
      expect(find.text('jobs.detail.linkCopied'), findsOneWidget);
    });

    for (final status in const [404, 400]) {
      testWidgets('a job that is not available ($status) says so', (
        tester,
      ) async {
        await _pump(
          tester,
          _adapter(job: (_) => jsonBody({'message': 'No'}, status: status)),
        );

        expect(find.text('jobs.detail.notAvailable.title'), findsOneWidget);
        expect(find.text('jobs.detail.apply'), findsNothing);
        expect(find.text('jobs.detail.signInToApply'), findsNothing);

        await tester.tap(find.text('jobs.detail.notAvailable.browse'));
        await tester.pumpAndSettle();
        expect(find.text('jobs page'), findsOneWidget);
      });
    }

    testWidgets('a server error offers to retry and never fake data', (
      tester,
    ) async {
      var fail = true;
      final adapter = _adapter(
        job: (_) => fail
            ? jsonBody({'message': 'Boom'}, status: 500)
            : jsonBody(_job(title: 'Recovered job')),
      );
      await _pump(tester, adapter);

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('jobs.detail.loadError.title'), findsOneWidget);
      expect(find.text('Boom'), findsNothing);

      fail = false;
      await tester.tap(find.text('errorState.retry'));
      await tester.pumpAndSettle();
      expect(find.text('Recovered job'), findsOneWidget);
    });
  });
}
