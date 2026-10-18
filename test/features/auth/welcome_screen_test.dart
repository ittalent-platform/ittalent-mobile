import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ittalent_mobile/config/routes.dart';
import 'package:ittalent_mobile/features/auth/welcome/welcome_screen.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';

void main() {
  testWidgets('WelcomeScreen renders brand, value propositions, and actions', (
    WidgetTester tester,
  ) async {
    String? navigatedRoute;

    final router = GoRouter(
      initialLocation: AppRoutes.welcome,
      routes: [
        GoRoute(
          path: AppRoutes.welcome,
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) {
            navigatedRoute = AppRoutes.register;
            return const Scaffold(body: Text('Register Screen'));
          },
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) {
            navigatedRoute = AppRoutes.login;
            return const Scaffold(body: Text('Login Screen'));
          },
        ),
        GoRoute(
          path: AppRoutes.jobs,
          builder: (context, state) {
            navigatedRoute = AppRoutes.jobs;
            return const Scaffold(body: Text('Jobs Screen'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );

    // Verify brand and hero copy
    expect(find.text('ITTALENT'), findsOneWidget);
    expect(find.text('Where IT careers\ntake shape.'), findsOneWidget);
    expect(find.text('Jobs from verified IT companies'), findsOneWidget);
    expect(find.text('One CV for every application'), findsOneWidget);
    expect(find.text('Track each application in one place'), findsOneWidget);

    // Verify action buttons
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Browse jobs first'), findsOneWidget);

    // Tap "Create account"
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(navigatedRoute, AppRoutes.register);

    // Reset and tap "Sign in"
    router.go(AppRoutes.welcome);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(navigatedRoute, AppRoutes.login);

    // Reset and tap "Browse jobs first"
    router.go(AppRoutes.welcome);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browse jobs first'));
    await tester.pumpAndSettle();
    expect(navigatedRoute, AppRoutes.jobs);
  });
}
