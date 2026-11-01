import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/client.dart';
import '../../auth/auth_notifier.dart';
import 'profile_model.dart';
import 'profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ApiProfileRepository(ref.watch(apiClientProvider)),
);

final profileProvider = AsyncNotifierProvider<ProfileNotifier, MyProfile>(
  ProfileNotifier.new,
  retry: (_, _) => null,
);

class ProfileNotifier extends AsyncNotifier<MyProfile> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  String _currentUserId() =>
      ref.read(currentUserIdProvider) ??
      (throw StateError('Profile requires an authenticated user'));

  MyProfile _ownedProfile(MyProfile profile, String userId) {
    if (!ref.mounted || _currentUserId() != userId || profile.id != userId) {
      throw StateError('Profile session changed');
    }
    return profile;
  }

  @override
  Future<MyProfile> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Profile requires an authenticated user');
    }
    final profile = await _repository.getProfile();
    return _ownedProfile(profile, userId);
  }

  Future<MyProfile> refresh() async {
    final userId = _currentUserId();
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () async => _ownedProfile(await _repository.getProfile(), userId),
    );
    if (!ref.mounted || ref.read(currentUserIdProvider) != userId) {
      throw StateError('Profile session changed');
    }
    state = next;
    return next.requireValue;
  }

  Future<MyProfile> saveProfile(ProfilePatch patch) async {
    final userId = _currentUserId();
    final profile = _ownedProfile(
      await _repository.updateProfile(patch),
      userId,
    );
    state = AsyncData(profile);
    return profile;
  }

  Future<MyProfile> uploadAvatar(
    Uint8List bytes,
    String name,
    String mimeType,
  ) async {
    final userId = _currentUserId();
    final profile = _ownedProfile(
      await _repository.uploadAvatar(bytes, name, mimeType),
      userId,
    );
    state = AsyncData(profile);
    return profile;
  }
}

final currentProfileProvider = Provider<MyProfile?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final profile = ref.watch(profileProvider);
  final value = profile.value;
  return !profile.isLoading && !profile.hasError && value?.id == userId
      ? value
      : null;
});
