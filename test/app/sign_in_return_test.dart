import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ittalent_mobile/app/router.dart';
import 'package:ittalent_mobile/auth/auth_notifier.dart';
import 'package:ittalent_mobile/auth/auth_state.dart';
import 'package:ittalent_mobile/auth/sign_in_return.dart';
import 'package:ittalent_mobile/config/routes.dart';

/// A guest that can sign in, so a test can change the auth state while the
/// router, its redirect and the pages it shows are the real ones.
class _Auth extends AuthNotifier {
  @override
  AuthState build() => AuthState.unauthenticated();

  void signIn() => state = AuthState.authenticated(userId: 'u1');
}

class _App {
  _App(this.container, this.router);

  final ProviderContainer container;
  final GoRouter router;

  void signIn() =>
      (container.read(authNotifierProvider.notifier) as _Auth).signIn();
}

Widget _screen(String name, [List<Widget> actions = const []]) =>
    Scaffold(body: Column(children: [Text(name), ...actions]));

class _Action extends StatelessWidget {
  const _Action(this.label, this.onPressed);

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      TextButton(onPressed: onPressed, child: Text(label));
}

/// The job page of the app: its two ways to ask a guest to sign in.
class _JobPage extends ConsumerWidget {
  const _JobPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) => _screen('job page', [
    _Action(
      'sign in to apply',
      () => signInThen(context, ref, AppRoutes.jobApply('j1')),
    ),
    _Action('save', () => signInThen(context, ref, AppRoutes.jobDetail('j1'))),
  ]);
}

/// The router of the app, as far as signing in is concerned: the welcome page
/// from which a guest browses (a push, so the welcome page stays the location
/// under everything), the job and its apply page, the login page, and the
/// applications a signed-in applicant lands on.
Future<_App> _pump(
  WidgetTester tester, {
  String initialLocation = AppRoutes.welcome,
}) async {
  final container = ProviderContainer(
    overrides: [authNotifierProvider.overrideWith(_Auth.new)],
  );
  addTearDown(container.dispose);
  final notifier = container.read(routerNotifierProvider);
  final router = GoRouter(
    initialLocation: initialLocation,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => _screen('welcome page', [
          _Action('browse', () => context.push(AppRoutes.jobs)),
          _Action('sign in', () => context.push(AppRoutes.login)),
        ]),
      ),
      GoRoute(
        path: AppRoutes.jobs,
        builder: (context, state) => _screen('jobs page', [
          _Action('open job', () => context.push(AppRoutes.jobDetail('j1'))),
        ]),
      ),
      GoRoute(
        path: '${AppRoutes.jobs}/:id',
        builder: (context, state) => const _JobPage(),
        routes: [
          GoRoute(
            path: 'apply',
            builder: (context, state) => _screen('apply page'),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => _screen('login page'),
      ),
      GoRoute(
        path: AppRoutes.myApplications,
        builder: (context, state) => _screen('applications page'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return _App(container, router);
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

/// A guest who browsed from the welcome page, to a job.
Future<_App> _browseToJob(WidgetTester tester) async {
  final app = await _pump(tester);
  await _tap(tester, 'browse');
  await _tap(tester, 'open job');
  expect(find.text('job page'), findsOneWidget);
  return app;
}

void main() {
  group('signing in from a job, with the real router', () {
    testWidgets('"Sign in to apply" comes back to the apply page', (
      tester,
    ) async {
      final app = await _browseToJob(tester);

      await _tap(tester, 'sign in to apply');
      expect(find.text('login page'), findsOneWidget);

      app.signIn();
      await tester.pumpAndSettle();

      expect(find.text('apply page'), findsOneWidget);
      expect(find.text('login page'), findsNothing);
      expect(find.text('applications page'), findsNothing);

      // Back from the apply page is the job, not the end of the app.
      app.router.pop();
      await tester.pumpAndSettle();
      expect(find.text('job page'), findsOneWidget);
    });

    testWidgets('"Save" comes back to the job', (tester) async {
      final app = await _browseToJob(tester);

      await _tap(tester, 'save');
      expect(find.text('login page'), findsOneWidget);

      app.signIn();
      await tester.pumpAndSettle();

      expect(find.text('job page'), findsOneWidget);
      expect(find.text('login page'), findsNothing);
      expect(find.text('applications page'), findsNothing);
    });

    testWidgets('a job opened by a link has the login page replace it', (
      tester,
    ) async {
      final app = await _pump(
        tester,
        initialLocation: AppRoutes.jobDetail('j1'),
      );
      expect(find.text('job page'), findsOneWidget);

      await _tap(tester, 'save');
      expect(find.text('login page'), findsOneWidget);

      app.signIn();
      await tester.pumpAndSettle();

      expect(find.text('job page'), findsOneWidget);
      expect(find.text('login page'), findsNothing);
    });

    testWidgets('"Sign in to apply" on a job opened by a link', (tester) async {
      final app = await _pump(
        tester,
        initialLocation: AppRoutes.jobDetail('j1'),
      );

      await _tap(tester, 'sign in to apply');
      expect(find.text('login page'), findsOneWidget);

      app.signIn();
      await tester.pumpAndSettle();

      expect(find.text('apply page'), findsOneWidget);
    });

    testWidgets('a link to the apply page asks to sign in, then opens it', (
      tester,
    ) async {
      final app = await _pump(
        tester,
        initialLocation: AppRoutes.jobApply('j1'),
      );
      expect(find.text('login page'), findsOneWidget);

      app.signIn();
      await tester.pumpAndSettle();

      expect(find.text('apply page'), findsOneWidget);
    });

    testWidgets(
      'signing in from the welcome page still opens My applications',
      (tester) async {
        final app = await _pump(tester);

        await _tap(tester, 'sign in');
        app.signIn();
        await tester.pumpAndSettle();

        expect(find.text('applications page'), findsOneWidget);
      },
    );

    testWidgets('backing out of the login page forgets where it was going', (
      tester,
    ) async {
      final app = await _browseToJob(tester);

      await _tap(tester, 'sign in to apply');
      app.router.pop();
      await tester.pumpAndSettle();
      expect(find.text('job page'), findsOneWidget);
      expect(app.container.read(signInReturnProvider), isNull);

      // Signing in later, from anywhere, is not sent to the apply page.
      app.signIn();
      await tester.pumpAndSettle();

      expect(find.text('applications page'), findsOneWidget);
      expect(find.text('apply page'), findsNothing);
    });

    testWidgets('the place is used once', (tester) async {
      final app = await _browseToJob(tester);
      await _tap(tester, 'sign in to apply');

      app.signIn();
      await tester.pumpAndSettle();

      expect(app.container.read(signInReturnProvider), isNull);
    });
  });
}
