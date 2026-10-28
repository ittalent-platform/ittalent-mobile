import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_error.dart';
import '../../components/common/app_toast.dart';
import '../../components/layout/screen_scaffold.dart';
import '../../components/ui/app_button.dart';
import '../../components/ui/app_input.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'profile_constants.dart';
import 'profile_model.dart';
import 'profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _nameError;
  String? _phoneError;
  bool _saving = false;
  MyProfile? _profile;
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _setProfile(MyProfile profile) {
    if (_profile == null) {
      _profile = profile;
      _name.text = profile.fullName ?? '';
      _phone.text = profile.phone ?? '';
    }
  }

  bool get _dirty =>
      _profile != null &&
      (_name.text.trim() != (_profile!.fullName ?? '') ||
          normalizePhone(_phone.text) != (_profile!.phone ?? ''));
  bool _validate() {
    final name = _name.text.trim();
    final phone = normalizePhone(_phone.text);
    setState(() {
      _nameError =
          name.length < profileNameMinLength ||
              name.length > profileNameMaxLength
          ? tr('profile.errors.name')
          : null;
      _phoneError = phone.isNotEmpty && !vietnamPhonePattern.hasMatch(phone)
          ? tr('profile.errors.phone')
          : null;
    });
    return _nameError == null && _phoneError == null;
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr('profile.discard.title')),
            content: Text(tr('profile.discard.message')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(tr('profile.discard.keep')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(tr('profile.discard.discard')),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _save() async {
    if (!_validate() || _profile == null) {
      return;
    }
    final patch = ProfilePatch.fromValues(_profile!, _name.text, _phone.text);
    if (patch == null) {
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(profileProvider.notifier).saveProfile(patch);
      if (mounted) {
        context.pop();
        showAppToast(messenger, tr('profile.saved'));
      }
    } on ApiError catch (error) {
      if (!mounted) return;
      if (error.isConflict) {
        final load = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr('profile.conflict.title')),
            content: Text(tr('profile.conflict.message')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(tr('common.cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(tr('profile.conflict.load')),
              ),
            ],
          ),
        );
        if (load == true) {
          final latest = await ref.read(profileProvider.notifier).refresh();
          if (mounted) {
            setState(() {
              _profile = latest;
              _name.text = latest.fullName ?? '';
              _phone.text = latest.phone ?? '';
            });
          }
        }
      } else {
        showAppToast(messenger, error.message, error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    if (profile != null && !profile.canMutate) {
      return ScreenScaffold(
        body: Center(child: Text(tr('profile.restricted.message'))),
      );
    }
    if (profile == null) {
      return const ScreenScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    _setProfile(profile);
    final valid = _nameError == null && _phoneError == null;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        final navigator = Navigator.of(context);
        final discard = await _confirmDiscard();
        if (discard && mounted) {
          navigator.pop();
        }
      },
      child: ScreenScaffold(
        appBar: AppBar(
          title: Text(tr('profile.edit')),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _confirmDiscard() && context.mounted) context.pop();
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Text(
                    tr('profile.editHint'),
                    style: AppTypography.body(
                      fontSize: 14,
                      color: context.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppInput(
                    label: tr('profile.fullName'),
                    isRequired: true,
                    controller: _name,
                    errorText: _nameError,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    label: tr('profile.phone'),
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    errorText: _phoneError,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: AppButton(
                text: tr('profile.save'),
                isFullWidth: true,
                isLoading: _saving,
                onPressed: _dirty && valid && !_saving ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
