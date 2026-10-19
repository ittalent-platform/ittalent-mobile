import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/auth/auth_dto.dart';
import 'package:ittalent_mobile/auth/auth_notifier.dart';
import 'package:ittalent_mobile/auth/auth_state.dart';
import 'package:ittalent_mobile/features/profile/me_screen.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';

class MockMeAuthNotifier extends AuthNotifier {
  MockMeAuthNotifier(this._initialState);

  final AuthState _initialState;
  bool logoutCalled = false;

  @override
  AuthState build() => _initialState;

  @override
  Future<void> logout() async {
    logoutCalled = true;
    state = AuthState.unauthenticated();
  }
}

void main() {
  Widget createWidget({required MockMeAuthNotifier notifier}) {
    return ProviderScope(
      overrides: [authNotifierProvider.overrideWith(() => notifier)],
      child: MaterialApp(theme: AppTheme.light, home: const MeScreen()),
    );
  }

  group('MeScreen Tests', () {
    testWidgets(
      'renders user profile details when authenticated with full name',
      (tester) async {
        final notifier = MockMeAuthNotifier(
          AuthState.authenticated(
            user: const UserDTO(
              id: 'u1',
              email: 'john.doe@techcorp.com',
              username: 'johndoe',
              fullName: 'John Doe',
              role: 'candidate',
            ),
          ),
        );

        await tester.pumpWidget(createWidget(notifier: notifier));
        await tester.pumpAndSettle();

        expect(find.text('Me'), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Project manager · Agile delivery'), findsOneWidget);
        expect(find.text('john.doe@techcorp.com'), findsOneWidget);
      },
    );

    testWidgets('falls back to username when fullName is absent', (
      tester,
    ) async {
      final notifier = MockMeAuthNotifier(
        AuthState.authenticated(
          user: const UserDTO(
            id: 'u2',
            email: 'dev.lead@example.com',
            username: 'leaddeveloper',
            role: 'candidate',
          ),
        ),
      );

      await tester.pumpWidget(createWidget(notifier: notifier));
      await tester.pumpAndSettle();

      expect(find.text('leaddeveloper'), findsOneWidget);
      expect(find.text('dev.lead@example.com'), findsOneWidget);
    });

    testWidgets('renders all menu groups and tiles with badges', (
      tester,
    ) async {
      final notifier = MockMeAuthNotifier(AuthState.initial());

      await tester.pumpWidget(createWidget(notifier: notifier));
      await tester.pumpAndSettle();

      // Groups
      expect(find.text('MY PROFILE'), findsOneWidget);
      expect(find.text('JOB SEARCH'), findsOneWidget);
      expect(find.text('ACCOUNT'), findsOneWidget);

      // MY PROFILE items
      expect(find.byKey(const Key('me_menu_profile')), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byKey(const Key('me_menu_documents')), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.byKey(const Key('me_menu_certificates')), findsOneWidget);
      expect(find.text('Certificates'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.byKey(const Key('me_menu_portfolio')), findsOneWidget);
      expect(find.text('Portfolio'), findsOneWidget);

      // JOB SEARCH items
      expect(find.byKey(const Key('me_menu_saved_jobs')), findsOneWidget);
      expect(find.text('Saved jobs'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.byKey(const Key('me_menu_my_reports')), findsOneWidget);
      expect(find.text('My reports'), findsOneWidget);

      // ACCOUNT items
      expect(find.byKey(const Key('me_menu_notifications')), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.byKey(const Key('me_menu_password')), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.byKey(const Key('me_menu_sign_out')), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('tapping Sign out triggers logout on authNotifier', (
      tester,
    ) async {
      final notifier = MockMeAuthNotifier(
        AuthState.authenticated(
          user: const UserDTO(
            id: 'u3',
            email: 'candidate@example.com',
            username: 'candidate',
            role: 'candidate',
          ),
        ),
      );

      await tester.pumpWidget(createWidget(notifier: notifier));
      await tester.pumpAndSettle();

      expect(notifier.logoutCalled, isFalse);

      final signOutFinder = find.byKey(const Key('me_menu_sign_out'));
      await tester.ensureVisible(signOutFinder);
      await tester.pumpAndSettle();

      await tester.tap(signOutFinder);
      await tester.pump();

      expect(notifier.logoutCalled, isTrue);
    });
  });
}
