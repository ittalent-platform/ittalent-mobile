import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ittalent_mobile/api/client.dart';
import 'package:ittalent_mobile/auth/auth_notifier.dart';
import 'package:ittalent_mobile/auth/auth_state.dart';
import 'package:ittalent_mobile/components/ui/app_button.dart';
import 'package:ittalent_mobile/config/routes.dart';
import 'package:ittalent_mobile/features/applicant/apply/apply_attempts.dart';
import 'package:ittalent_mobile/features/applicant/apply/apply_files.dart';
import 'package:ittalent_mobile/features/applicant/apply/apply_providers.dart';
import 'package:ittalent_mobile/features/applicant/apply/apply_screen.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';

import '../../helpers/fake_api.dart';

class _FakeAuth extends AuthNotifier {
  @override
  AuthState build() =>
      AuthState.authenticated(userId: 'u1', email: 'an@example.com');
}

/// The device store of the attempt that waits for an answer, in memory.
class _MemoryStore implements AttemptStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String name) async => data[name];

  @override
  Future<void> write(String name, String value) async {
    data[name] = value;
  }

  @override
  Future<void> delete(String name) async {
    data.remove(name);
  }
}

/// A picker that answers with [file] without opening anything.
class _FakeFiles extends ApplyFiles {
  _FakeFiles(this.file);

  final ApplyPickedFile file;

  @override
  Future<ApplyPickedFile?> pick() async => file;
}

String _daysAhead(int days) =>
    DateTime.now().add(Duration(days: days)).toUtc().toIso8601String();

Map<String, dynamic> _doc(
  String id,
  String name, {
  bool isDefault = false,
  int size = 412000,
}) => {
  'id': id,
  'fileName': name,
  'size': size,
  'isDefault': isDefault,
  'createdAt': '2026-10-01T12:00:00.000Z',
};

Map<String, dynamic> _job({String? expiresAt}) => {
  'id': 'j1',
  'title': 'Senior Backend Engineer',
  'enterprise': {'id': 'e1', 'name': 'Nimbus Pay'},
  'location': 'Ha Noi',
  'expiresAt': expiresAt ?? _daysAhead(20),
};

const _submittedId = '65f0a1b2c3d4e5f6a7b89011';

ResponseBody _created(RequestOptions options) =>
    jsonBody({'id': _submittedId}, status: 201);

/// The API of the apply flow. What a test does not set is the usual case: an
/// open job, a default CV and another one, no cover letter, no certificate,
/// and an application that is accepted.
FakeAdapter _adapter({
  ResponseBody Function(RequestOptions options)? job,
  List<Map<String, dynamic>>? cvs,
  List<Map<String, dynamic>> letters = const [],
  List<Map<String, dynamic>> certificates = const [],
  ResponseBody Function(RequestOptions options)? certificateLinks,
  ResponseBody Function(RequestOptions options)? documentList,
  List<Map<String, dynamic>> applications = const [],
  ResponseBody Function(RequestOptions options)? submit,
  ResponseBody Function(RequestOptions options)? upload,
}) => FakeAdapter((options) {
  final path = options.path;
  final post = options.method == 'POST';
  if (path == '/api/v1/job-postings/j1/public') {
    return (job ?? (_) => jsonBody(_job()))(options);
  }
  if (path == '/api/v1/documents' && post) {
    return (upload ?? (_) => jsonBody(_doc('cv9', 'New.pdf'), status: 201))(
      options,
    );
  }
  if (path == '/api/v1/documents' && documentList != null) {
    return documentList(options);
  }
  if (path == '/api/v1/documents') {
    final items = options.queryParameters['type'] == 'cv'
        ? (cvs ??
              [
                _doc('cv1', 'Resume.pdf', isDefault: true),
                _doc('cv2', 'Old CV.pdf'),
              ])
        : letters;
    return jsonBody({'items': items, 'total': items.length});
  }
  if (path == '/api/v1/me/certificate-links' && certificateLinks != null) {
    return certificateLinks(options);
  }
  if (path == '/api/v1/me/certificate-links') {
    return jsonBody({'items': certificates, 'total': certificates.length});
  }
  // The same path lists the applications (GET) and sends one (POST).
  if (path == '/api/v1/me/applications' && post) {
    return (submit ?? _created)(options);
  }
  if (path == '/api/v1/me/applications') {
    return jsonBody({'items': applications, 'total': applications.length});
  }
  throw StateError('Unexpected request to $path');
});

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeAdapter adapter, {
  Size size = const Size(390, 844),
  ApplyFiles? files,
  AttemptStore? attempts,
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
      authNotifierProvider.overrideWith(_FakeAuth.new),
      if (files != null) applyFilesProvider.overrideWithValue(files),
      applyAttemptsProvider.overrideWithValue(
        ApplyAttempts(attempts ?? _MemoryStore()),
      ),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: AppRoutes.jobApply('j1'),
    routes: [
      GoRoute(
        path: AppRoutes.jobs,
        builder: (context, state) => const Scaffold(body: Text('jobs page')),
      ),
      GoRoute(
        path: '${AppRoutes.jobs}/:id',
        builder: (context, state) => const Scaffold(body: Text('job page')),
        routes: [
          GoRoute(
            path: 'apply',
            builder: (context, state) =>
                ApplyScreen(jobId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.myApplications,
        builder: (context, state) =>
            const Scaffold(body: Text('applications page')),
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
  return container;
}

/// The body of the application that was sent.
Map<String, dynamic> _sent(FakeAdapter adapter) {
  final request = adapter.requests.lastWhere(
    (r) => r.path == '/api/v1/me/applications' && r.method == 'POST',
  );
  return request.data as Map<String, dynamic>;
}

/// The applications that were sent (the POSTs, not the lists).
List<RequestOptions> _posts(FakeAdapter adapter) => [
  for (final r in adapter.requests)
    if (r.path == '/api/v1/me/applications' && r.method == 'POST') r,
];

/// Whether the button with [text] can be pressed.
bool _enabled(WidgetTester tester, String text) =>
    tester.widget<AppButton>(find.widgetWithText(AppButton, text)).onPressed !=
    null;

/// A request that gets no answer at all: no connection, or a lost response.
ResponseBody _noAnswer(RequestOptions options) => throw DioException(
  requestOptions: options,
  type: DioExceptionType.connectionError,
);

Map<String, dynamic> _certificate(String id, String name) => {
  'id': id,
  'name': name,
  'url': 'https://www.credly.com/badges/$id',
  'suggested': true,
};

Future<void> _tap(WidgetTester tester, String text) async {
  final target = find.text(text);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Goes from step 1 to step 2 with the CV that is chosen.
Future<void> _continue(WidgetTester tester) => _tap(tester, 'apply.continue');

ApplyPickedFile _file(String name, {List<int>? bytes}) {
  final content = Uint8List.fromList(bytes ?? utf8.encode('%PDF-1.4 resume'));
  return ApplyPickedFile(
    name: name,
    size: content.length,
    readBytes: () async => content,
  );
}

void main() {
  setUpAll(() async {
    EasyLocalization.logger.enableLevels = [];
  });

  group('step 1', () {
    for (final size in const [Size(360, 800), Size(390, 844)]) {
      testWidgets('lists the CVs without overflow at ${size.width}px', (
        tester,
      ) async {
        await _pump(
          tester,
          _adapter(
            cvs: [
              _doc(
                'cv1',
                'A very long curriculum vitae file name, final version 3.pdf',
                isDefault: true,
              ),
              _doc('cv2', 'Old CV.pdf'),
            ],
          ),
          size: size,
        );

        expect(find.text('apply.title'), findsOneWidget);
        expect(find.textContaining('apply.step'), findsOneWidget);
        expect(find.text('Senior Backend Engineer'), findsOneWidget);
        expect(find.text('Old CV.pdf'), findsOneWidget);
        expect(find.text('apply.defaultCv'), findsOneWidget);
        expect(find.textContaining('412 KB'), findsNWidgets(2));
        expect(find.text('apply.noCoverLetter'), findsOneWidget);
        expect(find.text('apply.continue'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('reads every page of the CVs, so the default one is found', (
      tester,
    ) async {
      final adapter = _adapter(
        documentList: (options) {
          if (options.queryParameters['type'] != 'cv') {
            return jsonBody({'items': <Object>[], 'total': 0});
          }
          final first = options.queryParameters['page'] == 1;
          return jsonBody({
            'items': first
                ? [for (var i = 0; i < 100; i++) _doc('cv$i', 'CV $i.pdf')]
                : [_doc('cvLast', 'Default CV.pdf', isDefault: true)],
            'total': 101,
          });
        },
      );
      await _pump(tester, adapter);

      final pages = [
        for (final r in adapter.requests)
          if (r.path == '/api/v1/documents' &&
              r.queryParameters['type'] == 'cv')
            r.queryParameters['page'],
      ];
      expect(pages, [1, 2]);
      await _continue(tester);
      expect(find.text('Default CV.pdf'), findsOneWidget);
    });

    testWidgets('Continue asks to choose a CV when none is the default', (
      tester,
    ) async {
      await _pump(
        tester,
        _adapter(cvs: [_doc('cv1', 'Resume.pdf'), _doc('cv2', 'Old CV.pdf')]),
      );

      await _continue(tester);
      expect(find.text('apply.errors.chooseCv'), findsOneWidget);
      expect(find.text('apply.submit'), findsNothing);

      await _tap(tester, 'Old CV.pdf');
      expect(find.text('apply.errors.chooseCv'), findsNothing);
      await _continue(tester);
      expect(find.text('apply.submit'), findsOneWidget);
    });

    testWidgets('without any CV the step is one action, not Continue', (
      tester,
    ) async {
      await _pump(tester, _adapter(cvs: const []));

      expect(find.text('apply.noCv.title'), findsOneWidget);
      expect(find.text('apply.noCv.action'), findsOneWidget);
      expect(find.text('apply.continue'), findsNothing);
    });

    testWidgets('says an earlier application was withdrawn, and lets apply', (
      tester,
    ) async {
      await _pump(
        tester,
        _adapter(
          applications: [
            {
              'id': 'a1',
              'status': 'withdrawn',
              'canApplyAgain': true,
              'withdrawnAt': '2026-09-23T10:00:00.000Z',
            },
          ],
        ),
      );

      expect(find.text('apply.withdrewEarlier'), findsOneWidget);
      expect(find.text('apply.continue'), findsOneWidget);
    });

    testWidgets('Close asks before leaving, and keeps the application', (
      tester,
    ) async {
      await _pump(tester, _adapter());

      await tester.tap(find.byTooltip('actions.close'));
      await tester.pumpAndSettle();
      expect(find.text('apply.discard.title'), findsOneWidget);

      await _tap(tester, 'apply.discard.keep');
      expect(find.text('apply.discard.title'), findsNothing);
      expect(find.text('apply.continue'), findsOneWidget);

      await tester.tap(find.byTooltip('actions.close'));
      await tester.pumpAndSettle();
      await _tap(tester, 'apply.discard.confirm');
      expect(find.text('job page'), findsOneWidget);
    });
  });

  group('uploading', () {
    testWidgets('a PDF is saved, chosen and shown on the next step', (
      tester,
    ) async {
      final adapter = _adapter();
      await _pump(tester, adapter, files: _FakeFiles(_file('New.pdf')));

      await _tap(tester, 'apply.uploadCv');

      final post = adapter.requests.singleWhere(
        (r) => r.path == '/api/v1/documents' && r.method == 'POST',
      );
      final form = post.data as FormData;
      expect(form.fields.map((e) => '${e.key}=${e.value}'), ['type=cv']);
      expect(form.files.single.key, 'file');
      expect(form.files.single.value.filename, 'New.pdf');
      expect(find.text('New.pdf'), findsOneWidget);
      expect(find.text('apply.uploaded'), findsOneWidget);

      await _continue(tester);
      expect(find.text('New.pdf'), findsOneWidget);
      expect(find.text('Resume.pdf'), findsNothing);
    });

    testWidgets('a Word file is refused before anything is sent', (
      tester,
    ) async {
      final adapter = _adapter();
      await _pump(tester, adapter, files: _FakeFiles(_file('cv.docx')));

      await _tap(tester, 'apply.uploadCv');

      expect(find.text('apply.upload.wordFile'), findsOneWidget);
      expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
    });

    testWidgets('a file that is not a PDF inside is refused', (tester) async {
      final adapter = _adapter();
      await _pump(
        tester,
        adapter,
        files: _FakeFiles(_file('cv.pdf', bytes: utf8.encode('just text'))),
      );

      await _tap(tester, 'apply.uploadCv');

      expect(find.text('apply.upload.notPdf'), findsOneWidget);
      expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
    });

    testWidgets('a file over 5 MB is refused', (tester) async {
      final adapter = _adapter();
      await _pump(
        tester,
        adapter,
        files: _FakeFiles(
          ApplyPickedFile(
            name: 'big.pdf',
            size: 5000001,
            readBytes: () async => Uint8List(0),
          ),
        ),
      );

      await _tap(tester, 'apply.uploadCv');

      expect(find.text('apply.upload.tooLarge'), findsOneWidget);
      expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
    });

    testWidgets('a failed upload says so and keeps the list', (tester) async {
      await _pump(
        tester,
        _adapter(upload: (_) => jsonBody({'message': 'Boom'}, status: 500)),
        files: _FakeFiles(_file('New.pdf')),
      );

      await _tap(tester, 'apply.uploadCv');

      expect(find.text('apply.upload.failed'), findsOneWidget);
      expect(find.text('Resume.pdf'), findsOneWidget);
    });
  });

  group('step 2', () {
    testWidgets('shows the chosen documents, and Change goes back', (
      tester,
    ) async {
      await _pump(tester, _adapter());

      await _continue(tester);
      expect(find.text('Resume.pdf'), findsOneWidget);
      expect(find.text('apply.continue'), findsNothing);
      expect(find.text('apply.submit'), findsOneWidget);

      await _tap(tester, 'apply.change');
      expect(find.text('apply.continue'), findsOneWidget);
    });

    testWidgets('the back button returns to step 1', (tester) async {
      await _pump(tester, _adapter());
      await _continue(tester);

      await tester.tap(find.byTooltip('actions.back'));
      await tester.pumpAndSettle();

      expect(find.text('apply.continue'), findsOneWidget);
    });

    testWidgets('fits a 360px screen with certificates and a note', (
      tester,
    ) async {
      await _pump(
        tester,
        _adapter(
          certificates: [
            {
              'id': 'k1',
              'name': 'AWS Certified Solutions Architect – Professional',
              'url': 'https://www.credly.com/badges/aws',
              'suggested': true,
            },
          ],
        ),
        size: const Size(360, 800),
      );

      await _continue(tester);

      expect(find.text('apply.submit'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sends the CV, the suggested certificates and the note', (
      tester,
    ) async {
      final adapter = _adapter(
        certificates: [
          {
            'id': 'k1',
            'name': 'AWS',
            'url': 'https://www.credly.com/badges/aws',
            'suggested': true,
          },
          {'id': 'k2', 'name': 'GCP', 'url': 'https://example.org/gcp'},
        ],
      );
      await _pump(tester, adapter);
      await _continue(tester);

      await tester.enterText(find.byType(TextField), '  Hello team  ');
      await _tap(tester, 'GCP');
      await _tap(tester, 'apply.submit');

      final body = _sent(adapter);
      expect(body['jobPostingId'], 'j1');
      expect(body['cvId'], 'cv1');
      expect(body.containsKey('coverLetterId'), isFalse);
      expect(body['message'], 'Hello team');
      expect(body['certificateLinkIds'], unorderedEquals(['k1', 'k2']));
    });

    testWidgets('a certificate can be unticked, even a suggested one', (
      tester,
    ) async {
      final adapter = _adapter(
        certificates: [
          {
            'id': 'k1',
            'name': 'AWS',
            'url': 'https://www.credly.com/badges/aws',
            'suggested': true,
          },
        ],
      );
      await _pump(tester, adapter);
      await _continue(tester);

      await _tap(tester, 'AWS');
      await _tap(tester, 'apply.submit');

      expect(_sent(adapter).containsKey('certificateLinkIds'), isFalse);
    });

    testWidgets(
      'a certificate list that failed blocks Submit until it is read',
      (tester) async {
        var failing = true;
        final adapter = _adapter(
          certificateLinks: (_) => failing
              ? jsonBody({'message': 'Boom'}, status: 500)
              : jsonBody({
                  'items': [_certificate('k1', 'AWS')],
                  'total': 1,
                }),
        );
        await _pump(tester, adapter);
        await _continue(tester);

        // The choice of links is unknown: it must not be sent as "none".
        expect(find.text('apply.errors.loadCertificates'), findsOneWidget);
        expect(_enabled(tester, 'apply.submit'), isFalse);
        await tester.tap(find.text('apply.submit'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(_posts(adapter), isEmpty);

        failing = false;
        await _tap(tester, 'errorState.retry');

        expect(find.text('apply.errors.loadCertificates'), findsNothing);
        expect(find.text('AWS'), findsOneWidget);
        expect(_enabled(tester, 'apply.submit'), isTrue);
        await _tap(tester, 'apply.submit');
        expect(_sent(adapter)['certificateLinkIds'], ['k1']);
      },
    );

    testWidgets('a failing second page of certificates fails the whole list', (
      tester,
    ) async {
      final adapter = _adapter(
        certificateLinks: (options) {
          if (options.queryParameters['page'] == 1) {
            return jsonBody({
              'items': [
                for (var i = 0; i < 100; i++) _certificate('k$i', 'Cert $i'),
              ],
              'total': 130,
            });
          }
          return jsonBody({'message': 'Boom'}, status: 500);
        },
      );
      await _pump(tester, adapter);
      await _continue(tester);

      expect(find.text('apply.errors.loadCertificates'), findsOneWidget);
      expect(_enabled(tester, 'apply.submit'), isFalse);
      expect(_posts(adapter), isEmpty);
    });

    testWidgets('sends the cover letter that was chosen', (tester) async {
      final adapter = _adapter(letters: [_doc('cl1', 'Letter.pdf')]);
      await _pump(tester, adapter);

      await _tap(tester, 'Old CV.pdf');
      await _tap(tester, 'Letter.pdf');
      await _continue(tester);
      expect(find.text('Letter.pdf'), findsOneWidget);
      await _tap(tester, 'apply.submit');

      final body = _sent(adapter);
      expect(body['cvId'], 'cv2');
      expect(body['coverLetterId'], 'cl1');
    });
  });

  group('after Submit', () {
    testWidgets('says the application was sent and opens it', (tester) async {
      final container = await _pump(tester, _adapter());
      await _continue(tester);

      await _tap(tester, 'apply.submit');

      expect(find.text('apply.submitted.title'), findsOneWidget);
      expect(find.text('apply.submit'), findsNothing);
      // The lists of applications are told to read again.
      expect(container.read(applicationSubmittedProvider), 1);

      await _tap(tester, 'apply.submitted.view');
      expect(find.text('application page $_submittedId'), findsOneWidget);
    });

    testWidgets('Keep browsing goes to the job list', (tester) async {
      await _pump(tester, _adapter());
      await _continue(tester);
      await _tap(tester, 'apply.submit');

      await _tap(tester, 'apply.submitted.browse');

      expect(find.text('jobs page'), findsOneWidget);
    });

    testWidgets('a job that just filled says so and stays on step 2', (
      tester,
    ) async {
      await _pump(
        tester,
        _adapter(
          submit: (_) => jsonBody({
            'code': 'POSITION_FILLED',
            'message': 'Filled',
          }, status: 409),
        ),
      );
      await _continue(tester);

      await _tap(tester, 'apply.submit');

      expect(find.text('apply.errors.positionFilled'), findsOneWidget);
      expect(find.text('apply.submit'), findsOneWidget);
    });

    testWidgets('a rejected CV sends the applicant back to choose again', (
      tester,
    ) async {
      await _pump(
        tester,
        _adapter(
          submit: (_) =>
              jsonBody({'code': 'INVALID_CV', 'message': 'Gone'}, status: 400),
        ),
      );
      await _continue(tester);

      await _tap(tester, 'apply.submit');

      expect(find.text('apply.errors.cvUnavailable'), findsOneWidget);
      expect(find.text('apply.continue'), findsOneWidget);
    });

    testWidgets('a server error says it failed and keeps the application', (
      tester,
    ) async {
      final adapter = _adapter(
        submit: (_) => jsonBody({'message': 'Boom'}, status: 500),
      );
      await _pump(tester, adapter);
      await _continue(tester);

      await _tap(tester, 'apply.submit');

      // After a 5xx the application may exist: no claim that nothing was sent.
      expect(find.text('apply.errors.unconfirmed'), findsOneWidget);
      expect(find.text('apply.errors.submitFailed'), findsNothing);
      expect(find.text('Boom'), findsNothing);
      expect(find.text('apply.submit'), findsOneWidget);
    });

    testWidgets('an answer that never came is retried, and a second refusal '
        'as already applied is the first one succeeding', (tester) async {
      final applications = <Map<String, dynamic>>[];
      var attempt = 0;
      final adapter = _adapter(
        applications: applications,
        submit: (options) {
          attempt++;
          if (attempt == 1) {
            // The API created the application; only its answer was lost.
            applications.add({
              'id': _submittedId,
              'status': 'submitted',
              'canApplyAgain': false,
            });
            return _noAnswer(options);
          }
          return jsonBody({
            'code': 'ALREADY_APPLIED',
            'message': 'Applied',
          }, status: 409);
        },
      );
      final container = await _pump(tester, adapter);
      await _continue(tester);

      await _tap(tester, 'apply.submit');
      expect(find.text('apply.errors.offline'), findsOneWidget);
      expect(find.text('apply.submitted.title'), findsNothing);

      await _tap(tester, 'apply.submit');

      expect(_posts(adapter), hasLength(2));
      expect(find.text('apply.submitted.title'), findsOneWidget);
      expect(find.text('apply.blocked.alreadyApplied.title'), findsNothing);
      expect(container.read(applicationSubmittedProvider), 1);
      await _tap(tester, 'apply.submitted.view');
      expect(find.text('application page $_submittedId'), findsOneWidget);
    });

    testWidgets('a 5xx is doubtful too: its retry is reconciled the same way', (
      tester,
    ) async {
      final applications = <Map<String, dynamic>>[];
      var attempt = 0;
      await _pump(
        tester,
        _adapter(
          applications: applications,
          submit: (_) {
            attempt++;
            if (attempt == 1) {
              applications.add({
                'id': _submittedId,
                'status': 'submitted',
                'canApplyAgain': false,
              });
              return jsonBody({'message': 'Gateway'}, status: 502);
            }
            return jsonBody({
              'code': 'ALREADY_APPLIED',
              'message': 'Applied',
            }, status: 409);
          },
        ),
      );
      await _continue(tester);

      await _tap(tester, 'apply.submit');
      expect(find.text('apply.errors.unconfirmed'), findsOneWidget);
      await _tap(tester, 'apply.submit');

      expect(find.text('apply.submitted.title'), findsOneWidget);
    });

    testWidgets('already applied after a clear refusal is still the old page', (
      tester,
    ) async {
      // The first answer was a clear "no" (a 400): nothing doubtful, so the
      // second "already applied" is somebody else's application.
      var attempt = 0;
      await _pump(
        tester,
        _adapter(
          submit: (_) {
            attempt++;
            return attempt == 1
                ? jsonBody({
                    'code': 'INVALID_COVER_LETTER',
                    'message': 'Gone',
                  }, status: 400)
                : jsonBody({
                    'code': 'ALREADY_APPLIED',
                    'message': 'Applied',
                  }, status: 409);
          },
        ),
      );
      await _continue(tester);
      await _tap(tester, 'apply.submit');
      await _continue(tester);
      await _tap(tester, 'apply.submit');

      expect(find.text('apply.blocked.alreadyApplied.title'), findsOneWidget);
      expect(find.text('apply.submitted.title'), findsNothing);
    });

    testWidgets('a retry that is refused for another reason stays an error', (
      tester,
    ) async {
      var attempt = 0;
      await _pump(
        tester,
        _adapter(
          submit: (options) {
            attempt++;
            return attempt == 1
                ? _noAnswer(options)
                : jsonBody({
                    'code': 'POSITION_FILLED',
                    'message': 'Filled',
                  }, status: 409);
          },
        ),
      );
      await _continue(tester);

      await _tap(tester, 'apply.submit');
      await _tap(tester, 'apply.submit');

      expect(find.text('apply.errors.positionFilled'), findsOneWidget);
      expect(find.text('apply.submitted.title'), findsNothing);
    });

    testWidgets('a clear refusal says that nothing was sent', (tester) async {
      await _pump(
        tester,
        _adapter(
          submit: (_) => jsonBody({
            'code': 'VALIDATION_ERROR',
            'message': 'Bad',
          }, status: 400),
        ),
      );
      await _continue(tester);

      await _tap(tester, 'apply.submit');

      expect(find.text('apply.errors.submitFailed'), findsOneWidget);
      expect(find.text('apply.errors.unconfirmed'), findsNothing);
    });

    testWidgets('an email that is not verified takes the place of the steps', (
      tester,
    ) async {
      await _pump(
        tester,
        _adapter(
          submit: (_) => jsonBody({
            'code': 'EMAIL_NOT_VERIFIED',
            'message': 'Verify',
          }, status: 403),
        ),
      );
      await _continue(tester);

      await _tap(tester, 'apply.submit');

      expect(find.text('apply.blocked.emailNotVerified.title'), findsOneWidget);
      expect(find.text('apply.submit'), findsNothing);
    });

    testWidgets('a job applied to meanwhile shows the application page', (
      tester,
    ) async {
      await _pump(
        tester,
        _adapter(
          submit: (_) => jsonBody({
            'code': 'ALREADY_APPLIED',
            'message': 'Applied',
          }, status: 409),
        ),
      );
      await _continue(tester);

      await _tap(tester, 'apply.submit');

      expect(find.text('apply.blocked.alreadyApplied.title'), findsOneWidget);
    });
  });

  group('pages that stop an application', () {
    testWidgets('an application already sent replaces the steps', (
      tester,
    ) async {
      await _pump(
        tester,
        _adapter(
          applications: [
            {'id': 'a1', 'status': 'pending', 'canApplyAgain': false},
          ],
        ),
      );

      expect(find.text('apply.blocked.alreadyApplied.title'), findsOneWidget);
      expect(find.text('apply.continue'), findsNothing);

      await _tap(tester, 'apply.blocked.alreadyApplied.action');
      expect(find.text('application page a1'), findsOneWidget);
    });

    testWidgets('two applications sent leave no room for a third', (
      tester,
    ) async {
      await _pump(
        tester,
        _adapter(
          applications: [
            {'id': 'a2', 'status': 'withdrawn', 'canApplyAgain': false},
          ],
        ),
      );

      expect(find.text('apply.blocked.limit.title'), findsOneWidget);
      expect(find.text('apply.continue'), findsNothing);
    });

    testWidgets('a job that closed says so and goes back to the list', (
      tester,
    ) async {
      await _pump(
        tester,
        _adapter(job: (_) => jsonBody({'message': 'Gone'}, status: 404)),
      );

      expect(find.text('apply.blocked.jobClosed.title'), findsOneWidget);
      expect(find.text('apply.continue'), findsNothing);

      await _tap(tester, 'apply.blocked.jobClosed.action');
      expect(find.text('jobs page'), findsOneWidget);
    });

    testWidgets('a job past its deadline is closed too', (tester) async {
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
      );

      expect(find.text('apply.blocked.jobClosed.title'), findsOneWidget);
    });

    testWidgets('a job that cannot be read offers to retry', (tester) async {
      var fail = true;
      await _pump(
        tester,
        _adapter(
          job: (_) => fail
              ? jsonBody({'message': 'Boom'}, status: 500)
              : jsonBody(_job()),
        ),
      );
      expect(find.text('apply.errors.loadJobTitle'), findsOneWidget);

      fail = false;
      await _tap(tester, 'errorState.retry');

      expect(find.text('apply.continue'), findsOneWidget);
    });
  });

  group('sending again (BR-APP-009)', () {
    /// The key that the [index]th application was sent with.
    String? keyOf(FakeAdapter adapter, int index) =>
        _posts(adapter)[index].headers['Idempotency-Key'] as String?;

    testWidgets('an application is sent with a key that names the attempt', (
      tester,
    ) async {
      final adapter = _adapter();
      await _pump(tester, adapter);
      await _continue(tester);

      await _tap(tester, 'apply.submit');

      expect(keyOf(adapter, 0), matches(RegExp(r'^[0-9a-f]{32}$')));
    });

    testWidgets('after a lost answer the same key is sent again, and the API '
        'gives back the application the first send created', (tester) async {
      final created = <String, String>{};
      final adapter = _adapter(
        submit: (options) {
          final key = options.headers['Idempotency-Key'] as String;
          final known = created[key];
          // The API knows this attempt: it returns that application.
          if (known != null) return jsonBody({'id': known});
          // The first send is committed, and only its answer is lost.
          created[key] = _submittedId;
          return _noAnswer(options);
        },
      );
      final container = await _pump(tester, adapter);
      await _continue(tester);

      await _tap(tester, 'apply.submit');
      expect(find.text('apply.errors.offline'), findsOneWidget);
      await _tap(tester, 'apply.submit');

      expect(_posts(adapter), hasLength(2));
      expect(keyOf(adapter, 1), keyOf(adapter, 0));
      expect(find.text('apply.submitted.title'), findsOneWidget);
      expect(container.read(applicationSubmittedProvider), 1);
      await _tap(tester, 'apply.submitted.view');
      expect(find.text('application page $_submittedId'), findsOneWidget);
    });

    testWidgets('the key survives the app being closed between two sends', (
      tester,
    ) async {
      final device = _MemoryStore();
      final first = _adapter(submit: _noAnswer);
      await _pump(tester, first, attempts: device);
      await _continue(tester);
      await _tap(tester, 'apply.submit');
      expect(find.text('apply.errors.offline'), findsOneWidget);

      // The app is closed and opened again: only the device store is left.
      await tester.pumpWidget(const SizedBox.shrink());
      final second = _adapter();
      await _pump(tester, second, attempts: device);
      await _continue(tester);
      await _tap(tester, 'apply.submit');

      expect(keyOf(second, 0), keyOf(first, 0));
      expect(find.text('apply.submitted.title'), findsOneWidget);
    });

    testWidgets('a server error keeps the attempt, but a changed note starts '
        'a new one', (tester) async {
      final adapter = _adapter(
        submit: (_) => jsonBody({'message': 'Gateway'}, status: 502),
      );
      await _pump(tester, adapter);
      await _continue(tester);

      await _tap(tester, 'apply.submit');
      await _tap(tester, 'apply.submit');
      expect(keyOf(adapter, 1), keyOf(adapter, 0));

      await tester.enterText(find.byType(TextField), 'A new note');
      await _tap(tester, 'apply.submit');

      expect(keyOf(adapter, 2), isNot(keyOf(adapter, 0)));
    });

    testWidgets('a clear refusal ends the attempt: the next send is a new '
        'one', (tester) async {
      var attempt = 0;
      final adapter = _adapter(
        submit: (options) {
          attempt++;
          return attempt == 1
              ? jsonBody({'message': 'No'}, status: 400)
              : _created(options);
        },
      );
      await _pump(tester, adapter);
      await _continue(tester);

      await _tap(tester, 'apply.submit');
      expect(find.text('apply.errors.submitFailed'), findsOneWidget);
      await _tap(tester, 'apply.submit');

      expect(keyOf(adapter, 1), isNot(keyOf(adapter, 0)));
      expect(find.text('apply.submitted.title'), findsOneWidget);
    });

    testWidgets('an accepted application ends the attempt', (tester) async {
      final device = _MemoryStore();
      await _pump(tester, _adapter(), attempts: device);
      await _continue(tester);

      await _tap(tester, 'apply.submit');

      expect(find.text('apply.submitted.title'), findsOneWidget);
      expect(device.data, isEmpty);
    });

    testWidgets('an application found on the job settles the attempt that '
        'was waiting', (tester) async {
      final device = _MemoryStore();
      await _pump(tester, _adapter(submit: _noAnswer), attempts: device);
      await _continue(tester);
      await _tap(tester, 'apply.submit');
      expect(device.data, isNotEmpty);

      // It was created after all: the next time the job is opened, it is found.
      await tester.pumpWidget(const SizedBox.shrink());
      await _pump(
        tester,
        _adapter(
          applications: [
            {'id': _submittedId, 'status': 'submitted', 'canApplyAgain': false},
          ],
        ),
        attempts: device,
      );

      expect(find.text('apply.blocked.alreadyApplied.title'), findsOneWidget);
      expect(device.data, isEmpty);
    });
  });
}
