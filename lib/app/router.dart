import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/common/app_empty_state.dart';
import '../components/layout/screen_scaffold.dart';
import '../config/routes.dart';
import '../features/applicant/applications/applications_screen.dart';
import '../theme/app_colors.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.myApplications,
    routes: [
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
                  selectedIcon: Icon(LucideIcons.briefcase, color: colors.primary),
                  label: tr('accountNav.jobSearch'),
                ),
                NavigationDestination(
                  icon: const Icon(LucideIcons.fileText),
                  selectedIcon: Icon(LucideIcons.fileText, color: colors.primary),
                  label: tr('accountNav.myApplications'),
                ),
                NavigationDestination(
                  icon: const Icon(LucideIcons.user),
                  selectedIcon: Icon(LucideIcons.user, color: colors.primary),
                  label: tr('accountNav.myProfile'),
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
                    description: 'Search open tech positions matching your skills.',
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
                builder: (context, state) => ScreenScaffold(
                  appBar: AppBar(title: Text(tr('accountNav.myProfile'))),
                  body: AppEmptyState(
                    icon: const Icon(LucideIcons.user),
                    title: tr('accountNav.myProfile'),
                    description: 'Manage your candidate profile, resume, and skills.',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
