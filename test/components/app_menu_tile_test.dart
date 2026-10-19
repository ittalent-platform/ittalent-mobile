import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ittalent_mobile/components/ui/app_menu_tile.dart';
import 'package:ittalent_mobile/theme/app_theme.dart';

void main() {
  group('AppMenuTile Tests', () {
    testWidgets('renders title, icon, and chevron by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AppMenuTile(icon: LucideIcons.user, title: 'Profile'),
          ),
        ),
      );

      expect(find.text('Profile'), findsOneWidget);
      expect(find.byIcon(LucideIcons.user), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    });

    testWidgets('renders badge count correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AppMenuTile(
              icon: LucideIcons.fileText,
              title: 'Documents',
              badgeCount: 4,
            ),
          ),
        ),
      );

      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    });

    testWidgets('renders badge text when badgeText is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AppMenuTile(
              icon: LucideIcons.award,
              title: 'Certificates',
              badgeText: 'New',
            ),
          ),
        ),
      );

      expect(find.text('Certificates'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when pressed', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AppMenuTile(
              icon: LucideIcons.bell,
              title: 'Notifications',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Notifications'));
      expect(tapped, isTrue);
    });

    testWidgets('renders destructive styling without trailing chevron', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AppMenuTile(
              icon: LucideIcons.logOut,
              title: 'Sign out',
              isDestructive: true,
              showDivider: false,
            ),
          ),
        ),
      );

      expect(find.text('Sign out'), findsOneWidget);
      expect(find.byIcon(LucideIcons.logOut), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
    });
  });
}
