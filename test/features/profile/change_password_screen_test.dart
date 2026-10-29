import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ittalent_mobile/api/api_error.dart';
import 'package:ittalent_mobile/auth/token_storage.dart';
import 'package:ittalent_mobile/config/routes.dart';
import 'package:ittalent_mobile/features/profile/change_password_screen.dart';
import 'package:ittalent_mobile/features/profile/profile_providers.dart';

import 'profile_test_support.dart';

class _TokenStorage extends TokenStorage {
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> saveAccessToken(String token) async => accessToken = token;

  @override
  Future<void> saveRefreshToken(String token) async => refreshToken = token;
}

Finder input(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

Future<({GoRouter router, _TokenStorage tokens})> pumpPassword(
  WidgetTester tester,
  FakeProfileRepository repository,
) async {
  final tokens = _TokenStorage();
  final router = GoRouter(
    initialLocation: AppRoutes.changePassword,
    routes: [
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (_, _) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const Scaffold(body: Text('ME SCREEN')),
      ),
    ],
  );
  await tester.pumpWidget(
    localizedRouterApp(
      router: router,
      overrides: [
        profileRepositoryProvider.overrideWithValue(repository),
        tokenStorageProvider.overrideWithValue(tokens),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return (router: router, tokens: tokens);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeProfileTests();
  });

  testWidgets('same-as-current and confirm mismatch guidance update live', (
    tester,
  ) async {
    await pumpPassword(tester, FakeProfileRepository(testProfile()));
    await tester.enterText(input(const Key('password_current')), 'Abcd123!');
    await tester.enterText(input(const Key('password_new')), 'Abcd123!');
    await tester.pump();
    expect(
      find.text(
        'Choose a new password that is different from your current password.',
      ),
      findsOneWidget,
    );

    await tester.enterText(input(const Key('password_new')), 'Newpass1!');
    await tester.enterText(input(const Key('password_confirm')), 'Mismatch1!');
    expect(find.text('Passwords do not match.'), findsOneWidget);
    await tester.enterText(input(const Key('password_confirm')), 'Newpass1!');
    await tester.pump();
    expect(find.text('Passwords do not match.'), findsNothing);
  });

  testWidgets('visibility controls reveal each password field', (tester) async {
    await pumpPassword(tester, FakeProfileRepository(testProfile()));
    expect(
      tester.widget<TextField>(input(const Key('password_new'))).obscureText,
      isTrue,
    );
    await tester.tap(find.byKey(const Key('password_new_visibility')));
    await tester.pump();
    expect(
      tester.widget<TextField>(input(const Key('password_new'))).obscureText,
      isFalse,
    );
  });

  testWidgets('success replaces both tokens and returns to Me', (tester) async {
    final repository = FakeProfileRepository(testProfile());
    final result = await pumpPassword(tester, repository);
    await tester.enterText(input(const Key('password_current')), 'Oldpass1!');
    await tester.enterText(input(const Key('password_new')), 'Newpass1!');
    await tester.enterText(input(const Key('password_confirm')), 'Newpass1!');
    tester.testTextInput.hide();
    await tester.pump();
    await tester.tap(find.byKey(const Key('password_save')));
    await tester.pumpAndSettle();

    expect(repository.passwordCalls, 1);
    expect(result.tokens.accessToken, 'new-access');
    expect(result.tokens.refreshToken, 'new-refresh');
    expect(
      result.router.routeInformationProvider.value.uri.path,
      AppRoutes.profile,
    );
    expect(
      find.text('Password changed. Other devices were signed out.'),
      findsOneWidget,
    );
  });

  testWidgets('maps invalid current credential and rate limiting', (
    tester,
  ) async {
    final repository = FakeProfileRepository(testProfile())
      ..passwordError = const ApiError(
        message: 'bad',
        code: 'CURRENT_CREDENTIAL_INVALID',
      );
    await pumpPassword(tester, repository);
    await tester.enterText(input(const Key('password_current')), 'Oldpass1!');
    await tester.enterText(input(const Key('password_new')), 'Newpass1!');
    await tester.enterText(input(const Key('password_confirm')), 'Newpass1!');
    tester.testTextInput.hide();
    await tester.pump();
    await tester.tap(find.byKey(const Key('password_save')));
    await tester.pumpAndSettle();
    expect(find.text('Current password is incorrect.'), findsOneWidget);

    repository.passwordError = const ApiError(
      message: 'slow down',
      code: 'RATE_LIMITED',
    );
    await tester.enterText(input(const Key('password_current')), 'Oldpass2!');
    tester.testTextInput.hide();
    await tester.pump();
    await tester.tap(find.byKey(const Key('password_save')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Too many attempts'), findsOneWidget);
  });
}
