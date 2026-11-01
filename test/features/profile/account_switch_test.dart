import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ittalent_mobile/auth/auth_dto.dart';
import 'package:ittalent_mobile/auth/auth_notifier.dart';
import 'package:ittalent_mobile/auth/auth_state.dart';
import 'package:ittalent_mobile/features/applicant/certificates/certificates_providers.dart';
import 'package:ittalent_mobile/features/profile/edit_profile_screen.dart';
import 'package:ittalent_mobile/features/profile/me_screen.dart';
import 'package:ittalent_mobile/features/profile/profile_model.dart';
import 'package:ittalent_mobile/features/profile/profile_providers.dart';
import 'package:ittalent_mobile/features/profile/profile_screen.dart';
import 'package:ittalent_mobile/features/profile/widgets/profile_avatar.dart';

import 'profile_test_support.dart';

final _a = testProfile(avatarUrl: 'https://example.com/a.png');
final _b = testProfile(
  id: 'user-2',
  email: 'binh@example.com',
  username: 'binh',
  fullName: 'Tran Van Binh',
  avatarUrl: 'https://example.com/b.png',
  emailVerified: false,
);

AuthState _auth(MyProfile profile) => AuthState.authenticated(
  user: UserDTO(
    id: profile.id,
    email: profile.email,
    username: profile.username,
    fullName: profile.fullName,
    role: profile.role,
  ),
);

class _DelayedRepository extends FakeProfileRepository {
  _DelayedRepository(super.profile);

  Completer<MyProfile>? nextGet;
  Completer<MyProfile>? nextUpdate;

  @override
  Future<MyProfile> getProfile() {
    getCalls++;
    return nextGet?.future ?? Future.value(profile);
  }

  @override
  Future<MyProfile> updateProfile(ProfilePatch patch) {
    updateCalls++;
    return nextUpdate?.future ?? Future.value(profile);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeProfileTests);

  testWidgets('A sign out B replaces Me and Profile in one ProviderScope', (
    tester,
  ) async {
    final repository = FakeProfileRepository(_a);
    final page = ValueNotifier(0);
    addTearDown(page.dispose);
    await tester.pumpWidget(
      localizedApp(
        overrides: [
          profileRepositoryProvider.overrideWithValue(repository),
          certificateCountProvider.overrideWith((ref) async => 0),
        ],
        home: ValueListenableBuilder<int>(
          valueListenable: page,
          builder: (_, value, _) => switch (value) {
            1 => const ProfileScreen(),
            2 => const EditProfileScreen(),
            _ => const MeScreen(),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MeScreen)),
    );
    expect(find.text(_a.displayName), findsOneWidget);
    expect(find.text(_a.email), findsOneWidget);
    expect(
      tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).url,
      _a.avatarUrl,
    );

    await container.read(authNotifierProvider.notifier).logout();
    await tester.pump();
    expect(find.text(_a.displayName), findsNothing);
    expect(find.text(_a.email), findsNothing);
    expect(repository.getCalls, 1);

    repository.profile = _b;
    (container.read(authNotifierProvider.notifier) as TestProfileAuthNotifier)
        .setAuth(_auth(_b));
    await tester.pumpAndSettle();
    expect(find.text(_b.displayName), findsOneWidget);
    expect(find.text(_b.email), findsOneWidget);
    expect(find.text(_a.displayName), findsNothing);
    expect(
      tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).url,
      _b.avatarUrl,
    );

    page.value = 1;
    await tester.pumpAndSettle();
    expect(find.text(_b.displayName), findsWidgets);
    expect(find.text(_b.email), findsWidgets);
    expect(find.text(_a.displayName), findsNothing);
    expect(find.text(_a.email), findsNothing);
    expect(find.byKey(const Key('profile_verify_banner')), findsOneWidget);
    expect(find.text('Not verified'), findsOneWidget);
    expect(find.byKey(const Key('profile_edit')), findsNothing);
    expect(
      tester.widget<ProfileAvatar>(find.byKey(const Key('profile_avatar'))).url,
      _b.avatarUrl,
    );

    page.value = 2;
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile_name')), findsNothing);
    expect(find.text(_a.displayName), findsNothing);
  });

  testWidgets('Edit Profile replaces A form values when B signs in', (
    tester,
  ) async {
    final repository = FakeProfileRepository(_a);
    await tester.pumpWidget(
      localizedApp(
        overrides: [profileRepositoryProvider.overrideWithValue(repository)],
        home: const EditProfileScreen(),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(EditProfileScreen)),
    );
    TextField nameField() => tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('profile_name')),
        matching: find.byType(TextField),
      ),
    );
    expect(nameField().controller?.text, _a.fullName);

    final auth = container.read(
      authNotifierProvider.notifier,
    ) as TestProfileAuthNotifier;
    await auth.logout();
    await tester.pump();
    expect(find.byKey(const Key('profile_name')), findsNothing);

    final verifiedB = testProfile(
      id: _b.id,
      email: _b.email,
      username: _b.username,
      fullName: _b.fullName!,
    );
    repository.profile = verifiedB;
    auth.setAuth(_auth(verifiedB));
    await tester.pumpAndSettle();
    expect(nameField().controller?.text, verifiedB.fullName);
    expect(nameField().controller?.text, isNot(_a.fullName));
  });

  test('late A load and refresh cannot replace B', () async {
    final repository = _DelayedRepository(_a);
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(TestProfileAuthNotifier.new),
        profileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(profileProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(profileProvider.future);
    final auth = container.read(
      authNotifierProvider.notifier,
    ) as TestProfileAuthNotifier;

    final lateRefresh = Completer<MyProfile>();
    repository.nextGet = lateRefresh;
    final refresh = container.read(profileProvider.notifier).refresh();
    await auth.logout();
    repository
      ..nextGet = null
      ..profile = _b;
    auth.setAuth(_auth(_b));
    expect((await container.read(profileProvider.future)).id, _b.id);
    lateRefresh.complete(_a);
    await expectLater(refresh, throwsStateError);
    expect(container.read(currentProfileProvider)?.id, _b.id);

    final lateLoad = Completer<MyProfile>();
    await auth.logout();
    repository.nextGet = lateLoad;
    auth.setAuth(_auth(_a));
    final oldLoad = container.read(profileProvider.future);
    await auth.logout();
    repository
      ..nextGet = null
      ..profile = _b;
    auth.setAuth(_auth(_b));
    await container.read(profileProvider.future);
    lateLoad.complete(_a);
    await oldLoad.catchError((Object _) => _b);
    expect(container.read(currentProfileProvider)?.id, _b.id);
  });

  test('late A update cannot replace B', () async {
    final repository = _DelayedRepository(_a);
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(TestProfileAuthNotifier.new),
        profileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(profileProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(profileProvider.future);
    final lateUpdate = Completer<MyProfile>();
    repository.nextUpdate = lateUpdate;
    final update = container
        .read(profileProvider.notifier)
        .saveProfile(
          const ProfilePatch(
            expectedVersion: 3,
            includeFullName: true,
            includePhone: false,
            fullName: 'Updated A',
          ),
        );
    final auth = container.read(
      authNotifierProvider.notifier,
    ) as TestProfileAuthNotifier;
    await auth.logout();
    repository.profile = _b;
    auth.setAuth(_auth(_b));
    await container.read(profileProvider.future);
    lateUpdate.complete(_a);
    await expectLater(update, throwsStateError);
    expect(container.read(currentProfileProvider)?.id, _b.id);
  });
}
