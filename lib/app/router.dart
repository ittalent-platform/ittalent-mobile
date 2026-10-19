import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';
import '../components/common/app_empty_state.dart';
import '../components/layout/screen_scaffold.dart';
import '../config/routes.dart';
import '../features/applicant/applications/applications_screen.dart';
import '../features/auth/forgot_password/forgot_password_screen.dart';
import '../features/auth/forgot_password/reset_link_sent_screen.dart';
import '../features/auth/login/login_screen.dart';
import '../features/auth/register/register_screen.dart';
import '../features/auth/reset_password/reset_password_screen.dart';
import '../features/auth/verify_email/check_email_screen.dart';
import '../features/auth/verify_email/verify_email_screen.dart';
import '../features/auth/welcome/welcome_screen.dart';
import '../features/profile/me_screen.dart';
import '../theme/app_colors.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (previous, next) => notifyListeners());
  }

  final Ref _ref;

  AuthState get authState => _ref.read(authNotifierProvider);

  String? redirect(BuildContext context, GoRouterState state) {
    if (authState.status == AuthStatus.initial) {
      return null;
    }

    final loc = state.matchedLocation;
    final isAuthRoute =
        loc == AppRoutes.welcome ||
        loc == AppRoutes.login ||
        loc == AppRoutes.register ||
        loc == AppRoutes.forgotPassword ||
        loc == AppRoutes.resetLinkSent ||
        loc == AppRoutes.verifyEmail ||
        loc == AppRoutes.verifyEmailNotice ||
        loc == AppRoutes.emailVerified ||
        loc == AppRoutes.resetPassword;

    final isGuestAllowed = isAuthRoute || loc.startsWith(AppRoutes.jobs);

    if (!authState.isAuthenticated && !isGuestAllowed) {
      return AppRoutes.welcome;
    }

    if (authState.isAuthenticated &&
        (loc == AppRoutes.welcome ||
            loc == AppRoutes.login ||
            loc == AppRoutes.register ||
            loc == AppRoutes.forgotPassword ||
            loc == AppRoutes.resetLinkSent ||
            loc == AppRoutes.verifyEmailNotice ||
            loc == AppRoutes.emailVerified)) {
      return AppRoutes.myApplications;
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.myApplications,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmailNotice,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return CheckEmailScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetLinkSent,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return ResetLinkSentScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          final email = state.uri.queryParameters['email'];
          return VerifyEmailScreen(token: token, email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.emailVerified,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return VerifyEmailScreen(initialVerified: true, email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          final email = state.uri.queryParameters['email'];
          return ResetPasswordScreen(token: token, email: email);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final colors = context.colors;

          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              backgroundColor: colors.card,
              indicatorColor: colors.primary.withValues(alpha: 0.15),
              destinations: [
                NavigationDestination(
                  icon: const Icon(LucideIcons.briefcase),
                  selectedIcon: Icon(
                    LucideIcons.briefcase,
                    color: colors.primary,
                  ),
                  label: tr('accountNav.jobSearch'),
                ),
                NavigationDestination(
                  icon: const Icon(LucideIcons.fileText),
                  selectedIcon: Icon(
                    LucideIcons.fileText,
                    color: colors.primary,
                  ),
                  label: tr('accountNav.myApplications'),
                ),
                NavigationDestination(
                  icon: const Icon(LucideIcons.user),
                  selectedIcon: Icon(LucideIcons.user, color: colors.primary),
                  label: 'Me',
                ),
              ],
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.jobs,
                builder: (context, state) => ScreenScaffold(
                  appBar: AppBar(title: Text(tr('accountNav.jobSearch'))),
                  body: AppEmptyState(
                    icon: const Icon(LucideIcons.search),
                    title: tr('accountNav.jobSearch'),
                    description:
                        'Search open tech positions matching your skills.',
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.myApplications,
                builder: (context, state) => const ApplicationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const MeScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
