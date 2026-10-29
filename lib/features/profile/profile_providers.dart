import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/client.dart';
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

  @override
  Future<MyProfile> build() => _repository.getProfile();

  Future<MyProfile> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(_repository.getProfile);
    state = next;
    return next.requireValue;
  }

  Future<MyProfile> saveProfile(ProfilePatch patch) async {
    final profile = await _repository.updateProfile(patch);
    state = AsyncData(profile);
    return profile;
  }

  Future<MyProfile> uploadAvatar(
    Uint8List bytes,
    String name,
    String mimeType,
  ) async {
    final profile = await _repository.uploadAvatar(bytes, name, mimeType);
    state = AsyncData(profile);
    return profile;
  }
}
