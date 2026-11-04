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
  MockGoRouterState({required this.matchedLocation, Uri? uri})
    : uri = uri ?? Uri.parse(matchedLocation);

  @override
  final String matchedLocation;

  @override
  final Uri uri;
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

    test('lets a guest read a job, but sends them to sign in to apply', () {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeTestAuthNotifier(AuthState.unauthenticated()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider);
      String? redirect(String location) => notifier.redirect(
        _FakeContext(),
        MockGoRouterState(matchedLocation: location),
      );

      expect(redirect(AppRoutes.jobDetail('j1')), isNull);
      // To sign in, and back to the apply page afterwards.
      final toLogin = redirect(AppRoutes.jobApply('j1'));
      expect(toLogin, AppRoutes.loginThen(AppRoutes.jobApply('j1')));
      final login = Uri.parse(toLogin!);
      expect(login.path, AppRoutes.login);
      expect(login.queryParameters['from'], AppRoutes.jobApply('j1'));
      // That redirect is not redirected again: no loop.
      expect(
        notifier.redirect(
          _FakeContext(),
          MockGoRouterState(matchedLocation: AppRoutes.login, uri: login),
        ),
        isNull,
      );
    });

    test('a signed-in applicant on the login page goes back to where from', () {
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
      String? redirectTo(String? from) => notifier.redirect(
        _FakeContext(),
        MockGoRouterState(
          matchedLocation: AppRoutes.login,
          uri: Uri.parse(AppRoutes.loginThen(from)),
        ),
      );

      expect(redirectTo(AppRoutes.jobApply('j1')), AppRoutes.jobApply('j1'));
      expect(redirectTo(AppRoutes.jobDetail('j1')), AppRoutes.jobDetail('j1'));
      // No usable place: the usual landing page.
      expect(redirectTo(null), AppRoutes.myApplications);
      expect(
        notifier.redirect(
          _FakeContext(),
          MockGoRouterState(
            matchedLocation: AppRoutes.login,
            uri: Uri.parse('/login?from=https%3A%2F%2Fevil.example%2Fx'),
          ),
        ),
        AppRoutes.myApplications,
      );
    });

    test('lets a signed-in applicant apply to a job', () {
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
        MockGoRouterState(matchedLocation: AppRoutes.jobApply('j1')),
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
        AppRoutes.verifyEmailNotice,
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
          AppRoutes.verifyEmailNotice,
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
