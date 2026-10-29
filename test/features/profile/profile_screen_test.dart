import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/api/api_error.dart';
import 'package:ittalent_mobile/features/profile/profile_model.dart';
import 'package:ittalent_mobile/features/profile/profile_providers.dart';
import 'package:ittalent_mobile/features/profile/profile_screen.dart';

import 'profile_test_support.dart';

class _PendingRepository extends FakeProfileRepository {
  _PendingRepository(super.profile);

  final pending = Completer<MyProfile>();

  @override
  Future<MyProfile> getProfile() => pending.future;
}

Future<void> pumpProfile(
  WidgetTester tester,
  FakeProfileRepository repository,
) async {
  await tester.pumpWidget(
    localizedApp(
      home: const ProfileScreen(),
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeProfileTests();
  });

  testWidgets('loading uses AppSkeleton state', (tester) async {
    final repository = _PendingRepository(testProfile());
    await pumpProfile(tester, repository);
    expect(find.byKey(const Key('profile_loading')), findsOneWidget);
    repository.pending.complete(testProfile());
  });

  for (final item in [
    (403, 'Account restricted', 'profile_error_403'),
    (404, 'Profile unavailable', 'profile_error_404'),
    (500, 'Could not load profile', 'profile_error_500'),
  ]) {
    testWidgets('keeps ${item.$1} profile error distinct and translated', (
      tester,
    ) async {
      final repository = FakeProfileRepository(testProfile())
        ..getError = ApiError(message: 'failure', statusCode: item.$1);
      await pumpProfile(tester, repository);
      await tester.pumpAndSettle();
      expect(find.byKey(Key(item.$3)), findsOneWidget);
      expect(find.text(item.$2), findsOneWidget);
      expect(find.text('actions.retry'), findsNothing);
      expect(find.text('common.retry'), findsNothing);
    });
  }

  testWidgets('generic error retry loads the supported profile fields', (
    tester,
  ) async {
    final repository = FakeProfileRepository(testProfile())
      ..getError = const ApiError(message: 'offline');
    await pumpProfile(tester, repository);
    await tester.pumpAndSettle();
    repository.getError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repository.getCalls, 2);
    expect(find.text('Nguyen Van An'), findsWidgets);
    expect(find.text('0912345678'), findsOneWidget);
    expect(find.text('Candidate'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('candidate'), findsNothing);
    expect(find.text('active'), findsNothing);
    for (final excluded in [
      'Date of birth',
      'Gender',
      'Location',
      'Headline',
      'About',
      'Member since',
    ]) {
      expect(find.text(excluded), findsNothing);
    }
  });

  testWidgets('unverified email shows translated banner and badge', (
    tester,
  ) async {
    final repository = FakeProfileRepository(testProfile(emailVerified: false));
    await pumpProfile(tester, repository);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile_verify_banner')), findsOneWidget);
    expect(find.text('Not verified'), findsOneWidget);
    expect(find.text('profile.verifyBanner'), findsNothing);
  });
}
