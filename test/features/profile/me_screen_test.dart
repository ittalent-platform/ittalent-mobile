import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ittalent_mobile/auth/auth_dto.dart';
import 'package:ittalent_mobile/auth/auth_notifier.dart';
import 'package:ittalent_mobile/auth/auth_state.dart';
import 'package:ittalent_mobile/config/routes.dart';
import 'package:ittalent_mobile/features/applicant/certificates/certificates_providers.dart';
import 'package:ittalent_mobile/features/profile/me_screen.dart';
import 'package:ittalent_mobile/features/profile/profile_model.dart';
import 'package:ittalent_mobile/features/profile/profile_providers.dart';

import 'profile_test_support.dart';

class _AuthNotifier extends AuthNotifier {
  _AuthNotifier(this.initial);

  final AuthState initial;
  bool logoutCalled = false;

  @override
  AuthState build() => initial;

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

Future<({GoRouter router, _AuthNotifier auth})> pumpMe(
  WidgetTester tester, {
  required MyProfile profile,
}) async {
  final repository = FakeProfileRepository(profile);
  final auth = _AuthNotifier(
    AuthState.authenticated(
      user: const UserDTO(
        id: 'user-1',
        email: 'an@example.com',
        username: 'an.nguyen',
        fullName: 'Nguyen Van An',
        role: 'candidate',
      ),
    ),
  );
  final router = GoRouter(
    initialLocation: AppRoutes.profile,
    routes: [
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const MeScreen(),
        routes: [
          GoRoute(
            path: 'details',
            builder: (_, _) => const Scaffold(body: Text('PROFILE DETAILS')),
          ),
          GoRoute(
            path: 'password',
            builder: (_, _) => const Scaffold(body: Text('CHANGE PASSWORD')),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.certificates,
        builder: (_, _) => const Scaffold(body: Text('CERTIFICATES')),
      ),
      GoRoute(
        path: AppRoutes.portfolio,
        builder: (_, _) => const Scaffold(body: Text('PORTFOLIO')),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const Scaffold(body: Text('NOTIFICATIONS')),
      ),
    ],
  );
  await tester.pumpWidget(
    localizedRouterApp(
      router: router,
      overrides: [
        authNotifierProvider.overrideWith(() => auth),
        profileRepositoryProvider.overrideWithValue(repository),
        certificateCountProvider.overrideWith((ref) async => 2),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return (router: router, auth: auth);
}

Future<void> reveal(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    250,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeProfileTests();
  });

  testWidgets('card and Profile tile open Profile details', (tester) async {
    final first = await pumpMe(tester, profile: testProfile());
    await tester.tap(find.byKey(const Key('me_profile_card')));
    await tester.pumpAndSettle();
    expect(find.text('PROFILE DETAILS'), findsOneWidget);

    first.router.go(AppRoutes.profile);
    await tester.pumpAndSettle();
    await reveal(tester, const Key('me_menu_profile'));
    await tester.tap(find.byKey(const Key('me_menu_profile')));
    await tester.pumpAndSettle();
    expect(find.text('PROFILE DETAILS'), findsOneWidget);
  });

  testWidgets('Saved jobs never opens Change password', (tester) async {
    final result = await pumpMe(tester, profile: testProfile());
    await reveal(tester, const Key('me_menu_saved_jobs'));
    await tester.tap(find.byKey(const Key('me_menu_saved_jobs')));
    await tester.pumpAndSettle();
    expect(
      result.router.routeInformationProvider.value.uri.path,
      AppRoutes.profile,
    );
    expect(find.text('CHANGE PASSWORD'), findsNothing);
  });

  testWidgets('Password opens Change password when mutation is allowed', (
    tester,
  ) async {
    await pumpMe(tester, profile: testProfile());
    await reveal(tester, const Key('me_menu_password'));
    await tester.tap(find.byKey(const Key('me_menu_password')));
    await tester.pumpAndSettle();
    expect(find.text('CHANGE PASSWORD'), findsOneWidget);
  });

  for (final profile in [
    testProfile(hasPassword: false),
    testProfile(emailVerified: false),
    testProfile(status: 'suspended'),
  ]) {
    testWidgets('Password stays disabled when account cannot change it', (
      tester,
    ) async {
      final result = await pumpMe(tester, profile: profile);
      await reveal(tester, const Key('me_menu_password'));
      await tester.tap(find.byKey(const Key('me_menu_password')));
      await tester.pumpAndSettle();
      expect(
        result.router.routeInformationProvider.value.uri.path,
        AppRoutes.profile,
      );
    });
  }

  testWidgets('shows only real certificate count and no headline or raw role', (
    tester,
  ) async {
    await pumpMe(tester, profile: testProfile(role: 'candidate'));
    expect(find.text('Nguyen Van An'), findsOneWidget);
    expect(find.text('an@example.com'), findsOneWidget);
    expect(find.text('candidate'), findsNothing);
    expect(find.textContaining('Agile'), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });
}
