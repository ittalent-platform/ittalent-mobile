import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../api/api_error.dart';
import '../../components/common/app_error_state.dart';
import '../../components/common/app_toast.dart';
import '../../components/layout/screen_scaffold.dart';
import '../../components/ui/app_button.dart';
import '../../components/ui/app_card.dart';
import '../../config/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'profile_model.dart';
import 'profile_constants.dart';
import 'profile_providers.dart';
import 'widgets/profile_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return ScreenScaffold(
      appBar: AppBar(
        title: Text(tr('profile.title')),
        actions: [
          if (profile.value?.canMutate == true)
            IconButton(
              onPressed: () => context.push(AppRoutes.editProfile),
              icon: const Icon(LucideIcons.pencil),
              tooltip: tr('profile.edit'),
            ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _error(context, ref, error),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.read(profileProvider.notifier).refresh(),
          child: ListView(children: [_body(context, ref, data)]),
        ),
      ),
    );
  }

  Widget _error(BuildContext context, WidgetRef ref, Object error) {
    final api = error is ApiError ? error : null;
    final key = api?.statusCode == 403
        ? 'profile.restricted'
        : api?.statusCode == 404
        ? 'profile.missing'
        : 'profile.loadError';
    return AppErrorState(
      title: tr('$key.title'),
      message: tr('$key.message'),
      retryText: tr('common.retry'),
      onRetry: () => ref.read(profileProvider.notifier).refresh(),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, MyProfile profile) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!profile.canMutate)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.statusWarningBg,
              border: Border.all(color: colors.statusWarningBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tr('profile.verifyBanner'),
              style: AppTypography.body(
                fontSize: 14,
                color: colors.statusWarningFg,
              ),
            ),
          ),
        Center(
          child: Column(
            children: [
              ProfileAvatar(
                name: profile.displayName,
                url: profile.avatarUrl,
                size: 88,
                onTap: profile.canMutate
                    ? () => AvatarSheet.show(context, ref, profile)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                profile.displayName,
                style: AppTypography.display(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
              Text(
                profile.email,
                style: AppTypography.body(
                  fontSize: 14,
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _Section(
          title: tr('profile.personal'),
          rows: [
            tr('profile.fullName'),
            profile.fullName ?? '—',
            tr('profile.phone'),
            profile.phone ?? '—',
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: tr('profile.account'),
          rows: [
            tr('profile.email'),
            profile.email,
            tr('profile.role'),
            profile.role,
            tr('profile.status'),
            profile.status,
            if (profile.enterpriseName != null) ...[
              tr('profile.company'),
              profile.enterpriseName!,
            ],
          ],
        ),
        if (profile.canMutate && profile.hasPassword) ...[
          const SizedBox(height: 16),
          AppButton(
            text: tr('profile.changePassword'),
            icon: const Icon(LucideIcons.key),
            isFullWidth: true,
            variant: AppButtonVariant.outline,
            onPressed: () => context.push(AppRoutes.changePassword),
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});
  final String title;
  final List<String> rows;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < rows.length; i += 2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i],
                      style: AppTypography.body(
                        fontSize: 14,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i + 1],
                      textAlign: TextAlign.end,
                      style: AppTypography.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class AvatarSheet {
  static void show(BuildContext context, WidgetRef ref, MyProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AvatarPicker(ref: ref, profile: profile),
    );
  }
}

class _AvatarPicker extends StatefulWidget {
  const _AvatarPicker({required this.ref, required this.profile});
  final WidgetRef ref;
  final MyProfile profile;
  @override
  State<_AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<_AvatarPicker> {
  Uint8List? _bytes;
  String? _name;
  String? _mime;
  String? _error;
  bool _saving = false;
  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final mime = file.mimeType ?? _mimeFor(file.name);
    if (!isAllowedAvatarFile(length: bytes.length, mimeType: mime)) {
      setState(() => _error = tr('profile.avatarInvalid'));
      return;
    }
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      codec.dispose();
      setState(() {
        _bytes = bytes;
        _name = file.name;
        _mime = mime;
        _error = null;
      });
    } catch (_) {
      setState(() => _error = tr('profile.avatarInvalid'));
    }
  }

  String _mimeFor(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.png')
        ? 'image/png'
        : lower.endsWith('.webp')
        ? 'image/webp'
        : 'image/jpeg';
  }

  Future<void> _save() async {
    if (_bytes == null || _name == null || _mime == null) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.ref
          .read(profileProvider.notifier)
          .uploadAvatar(_bytes!, _name!, _mime!);
      if (mounted) {
        Navigator.pop(context);
        showAppToast(messenger, tr('profile.avatarSaved'));
      }
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr('profile.avatarTitle'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (_bytes != null)
            ClipOval(
              child: Image.memory(
                _bytes!,
                width: 160,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!),
            ),
          const SizedBox(height: 16),
          AppButton(
            text: tr('profile.takePhoto'),
            isFullWidth: true,
            variant: AppButtonVariant.outline,
            onPressed: _saving ? null : () => _pick(ImageSource.camera),
          ),
          const SizedBox(height: 8),
          AppButton(
            text: tr('profile.choosePhoto'),
            isFullWidth: true,
            variant: AppButtonVariant.outline,
            onPressed: _saving ? null : () => _pick(ImageSource.gallery),
          ),
          const SizedBox(height: 12),
          if (_bytes != null)
            AppButton(
              text: tr('profile.savePhoto'),
              isFullWidth: true,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          const SizedBox(height: 8),
          AppButton(
            text: tr('common.cancel'),
            isFullWidth: true,
            variant: AppButtonVariant.ghost,
            onPressed: _saving ? null : () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}
