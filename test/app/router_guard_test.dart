import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ittalent_mobile/app/router.dart';
import 'package:ittalent_mobile/auth/auth_dto.dart';
import 'package:ittalent_mobile/auth/auth_notifier.dart';
import 'package:ittalent_mobile/auth/auth_state.dart';
import 'package:ittalent_mobile/config/routes.dart';

class MockGoRouterState extends Fake implements GoRouterState {
  MockGoRouterState({required this.matchedLocation});

  @override
  final String matchedLocation;
}

void main() {
  group('RouterNotifier Guard Tests', () {
    test('does not redirect when authState is initial', () {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeTestAuthNotifier(AuthState.initial()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider);
      final result = notifier.redirect(
        _FakeContext(),
        MockGoRouterState(matchedLocation: AppRoutes.myApplications),
      );

      expect(result, isNull);
    });

    test('redirects unauthenticated user from protected route to welcome', () {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeTestAuthNotifier(AuthState.unauthenticated()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider);
      final result = notifier.redirect(
        _FakeContext(),
        MockGoRouterState(matchedLocation: AppRoutes.myApplications),
      );

      expect(result, AppRoutes.welcome);
    });

    test('allows unauthenticated user to access public guest jobs route', () {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeTestAuthNotifier(AuthState.unauthenticated()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider);
      final result = notifier.redirect(
        _FakeContext(),
        MockGoRouterState(matchedLocation: AppRoutes.jobs),
      );

      expect(result, isNull);
    });

    test('allows unauthenticated user to access auth screens', () {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeTestAuthNotifier(AuthState.unauthenticated()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider);

      for (final route in [
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.verifyEmail,
        AppRoutes.resetPassword,
      ]) {
        final result = notifier.redirect(
          _FakeContext(),
          MockGoRouterState(matchedLocation: route),
        );
        expect(result, isNull, reason: 'Route $route should be accessible');
      }
    });

    test(
      'redirects authenticated user from auth screens to myApplications',
      () {
        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith(
              () => FakeTestAuthNotifier(
                AuthState.authenticated(
                  user: const UserDTO(
                    id: 'usr-1',
                    email: 'test@example.com',
                    username: 'test',
                    role: 'candidate',
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(routerNotifierProvider);

        for (final route in [
          AppRoutes.welcome,
          AppRoutes.login,
          AppRoutes.register,
        ]) {
          final result = notifier.redirect(
            _FakeContext(),
            MockGoRouterState(matchedLocation: route),
          );
          expect(result, AppRoutes.myApplications);
        }
      },
    );

    test('allows authenticated user to access protected routes', () {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeTestAuthNotifier(
              AuthState.authenticated(
                user: const UserDTO(
                  id: 'usr-1',
                  email: 'test@example.com',
                  username: 'test',
                  role: 'candidate',
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider);

      final result = notifier.redirect(
        _FakeContext(),
        MockGoRouterState(matchedLocation: AppRoutes.myApplications),
      );
      expect(result, isNull);
    });
  });
}

class FakeTestAuthNotifier extends AuthNotifier {
  FakeTestAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  AuthState build() => _initialState;
}

class _FakeContext extends Fake implements BuildContext {}
