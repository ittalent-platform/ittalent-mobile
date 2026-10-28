import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:typed_data';

import '../../api/client.dart';
import 'profile_model.dart';
import 'profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);
final profileProvider = AsyncNotifierProvider<ProfileNotifier, MyProfile>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<MyProfile> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);
  @override
  Future<MyProfile> build() => _repository.getProfile();
  Future<MyProfile> refresh() async {
    final profile = await _repository.getProfile();
    state = AsyncData(profile);
    return profile;
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
