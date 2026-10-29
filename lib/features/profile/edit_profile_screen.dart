import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../api/api_error.dart';
import '../../components/common/app_toast.dart';
import '../../components/layout/screen_scaffold.dart';
import '../../components/ui/app_button.dart';
import '../../components/ui/app_card.dart';
import '../../components/ui/app_input.dart';
import '../../components/ui/app_skeleton.dart';
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
  String? _apiError;
  bool _saving = false;
  MyProfile? _profile;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _setInitialProfile(MyProfile profile) {
    if (_profile != null) return;
    _profile = profile;
    _name.text = profile.fullName ?? '';
    _phone.text = profile.phone ?? '';
  }

  bool get _dirty =>
      _profile != null &&
      (_name.text.trim() != (_profile!.fullName ?? '') ||
          normalizePhone(_phone.text) != (_profile!.phone ?? ''));

  bool get _valuesValid =>
      isValidProfileName(_name.text) && isValidProfilePhone(_phone.text);

  bool get _canSave => _dirty && _valuesValid && !_saving;

  String? _nameValidation() =>
      isValidProfileName(_name.text) ? null : tr('profile.errors.name');

  String? _phoneValidation() =>
      isValidProfilePhone(_phone.text) ? null : tr('profile.errors.phone');

  bool _validate() {
    setState(() {
      _nameError = _nameValidation();
      _phoneError = _phoneValidation();
    });
    return _nameError == null && _phoneError == null;
  }

  void _nameChanged(String _) {
    setState(() {
      _apiError = null;
      _nameError = _nameValidation();
    });
  }

  void _phoneChanged(String _) {
    setState(() {
      _apiError = null;
      _phoneError = _phoneValidation();
    });
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
    if (!_validate() || _profile == null || _saving) return;
    final patch = ProfilePatch.fromValues(_profile!, _name.text, _phone.text);
    if (patch == null) return;

    setState(() {
      _saving = true;
      _apiError = null;
    });
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
        final loadLatest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            key: const Key('profile_conflict_dialog'),
            title: Text(tr('profile.conflict.title')),
            content: Text(tr('profile.conflict.message')),
            actions: [
              TextButton(
                key: const Key('profile_conflict_cancel'),
                onPressed: () => Navigator.pop(context, false),
                child: Text(tr('actions.cancel')),
              ),
              TextButton(
                key: const Key('profile_conflict_load'),
                onPressed: () => Navigator.pop(context, true),
                child: Text(tr('profile.conflict.load')),
              ),
            ],
          ),
        );
        if (loadLatest == true) {
          final latest = await ref.read(profileProvider.notifier).refresh();
          if (mounted) {
            setState(() {
              _profile = latest;
              _name.text = latest.fullName ?? '';
              _phone.text = latest.phone ?? '';
              _nameError = null;
              _phoneError = null;
              _apiError = null;
            });
          }
        }
      } else {
        setState(() => _apiError = tr('profile.updateError'));
      }
    } catch (_) {
      if (mounted) setState(() => _apiError = tr('profile.updateError'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncProfile = ref.watch(profileProvider);
    final profile = asyncProfile.value;
    if (profile == null) {
      return ScreenScaffold(
        appBar: AppBar(title: Text(tr('profile.edit'))),
        body: const Column(
          key: Key('edit_profile_loading'),
          children: [
            AppSkeleton(height: 20),
            SizedBox(height: 20),
            AppSkeleton(height: 72),
            SizedBox(height: 16),
            AppSkeleton(height: 92),
          ],
        ),
      );
    }
    if (!profile.canMutate) {
      return ScreenScaffold(
        appBar: AppBar(title: Text(tr('profile.edit'))),
        body: Center(child: Text(tr('profile.restricted.message'))),
      );
    }
    _setInitialProfile(profile);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard() && mounted) navigator.pop();
      },
      child: ScreenScaffold(
        appBar: AppBar(
          title: Text(tr('profile.edit')),
          leading: IconButton(
            icon: const Icon(LucideIcons.x),
            tooltip: tr('actions.close'),
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
                    key: const Key('profile_name'),
                    label: tr('profile.fullName'),
                    isRequired: true,
                    controller: _name,
                    errorText: _nameError,
                    onChanged: _nameChanged,
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    key: const Key('profile_phone'),
                    label: tr('profile.phone'),
                    helperText: tr('profile.phoneHelper'),
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    errorText: _phoneError,
                    onChanged: _phoneChanged,
                  ),
                  if (_apiError != null) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      key: const Key('profile_update_error'),
                      backgroundColor: context.colors.statusErrorBg,
                      borderColor: context.colors.destructive.withValues(
                        alpha: .2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _apiError!,
                            style: AppTypography.body(
                              fontSize: 14,
                              color: context.colors.statusErrorFg,
                            ),
                          ),
                          const SizedBox(height: 10),
                          AppButton(
                            key: const Key('profile_update_retry'),
                            text: tr('actions.retry'),
                            size: AppButtonSize.sm,
                            variant: AppButtonVariant.outline,
                            onPressed: _canSave ? _save : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: AppButton(
                key: const Key('profile_save'),
                text: tr('profile.save'),
                isFullWidth: true,
                isLoading: _saving,
                onPressed: _canSave ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
