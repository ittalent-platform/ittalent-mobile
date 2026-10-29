import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../api/api_error.dart';
import '../../../components/common/app_toast.dart';
import '../../../components/ui/app_button.dart';
import '../../../components/ui/app_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../profile_model.dart';
import '../profile_providers.dart';
import 'avatar_file.dart';
import 'profile_avatar.dart';

typedef PickAvatar = Future<XFile?> Function(ImageSource source);

final avatarPickerProvider = Provider<PickAvatar>(
  (ref) =>
      (source) => ImagePicker().pickImage(source: source),
);

final avatarDecoderProvider = Provider<AvatarDecoder>((ref) => decodeAvatar);

class AvatarPhotoSheet extends ConsumerStatefulWidget {
  const AvatarPhotoSheet({super.key, required this.profile});

  final MyProfile profile;

  static Future<void> show(BuildContext context, MyProfile profile) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => AvatarPhotoSheet(profile: profile),
      );

  @override
  ConsumerState<AvatarPhotoSheet> createState() => _AvatarPhotoSheetState();
}

class _AvatarPhotoSheetState extends ConsumerState<AvatarPhotoSheet> {
  final _cropKey = GlobalKey();
  ValidatedAvatarFile? _file;
  String? _error;
  bool _saving = false;

  Future<void> _pick(ImageSource source) async {
    final picked = await ref.read(avatarPickerProvider)(source);
    if (picked == null || !mounted) return;

    setState(() {
      _file = null;
      _error = null;
    });

    try {
      final bytes = await picked.readAsBytes();
      final validated = await validateAvatarFile(
        bytes: bytes,
        name: picked.name,
        decoder: ref.read(avatarDecoderProvider),
      );
      if (mounted) setState(() => _file = validated);
    } on AvatarValidationException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } catch (_) {
      if (mounted) setState(() => _error = tr('profile.avatarUnreadable'));
    }
  }

  String _messageFor(AvatarValidationException exception) {
    return switch (exception.error) {
      AvatarValidationError.unsupported => tr('profile.avatarUnsupported'),
      AvatarValidationError.tooLarge => tr(
        'profile.avatarTooLarge',
        namedArgs: {'size': avatarSizeLabel(exception.byteLength ?? 0)},
      ),
      AvatarValidationError.corrupt => tr('profile.avatarUnreadable'),
    };
  }

  Future<({Uint8List bytes, String name, String mime})> _uploadBody() async {
    final boundary = _cropKey.currentContext?.findRenderObject();
    if (boundary is RenderRepaintBoundary) {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data != null) {
        return (
          bytes: data.buffer.asUint8List(),
          name: 'profile-photo.png',
          mime: AvatarFormat.png.mimeType,
        );
      }
    }
    final file = _file!;
    return (bytes: file.bytes, name: file.name, mime: file.format.mimeType);
  }

  Future<void> _save() async {
    if (_file == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final body = await _uploadBody();
      await ref
          .read(profileProvider.notifier)
          .uploadAvatar(body.bytes, body.name, body.mime);
      if (mounted) {
        Navigator.pop(context);
        showAppToast(messenger, tr('profile.avatarSaved'));
      }
    } on ApiError {
      if (mounted) setState(() => _error = tr('profile.avatarUploadError'));
    } catch (_) {
      if (mounted) setState(() => _error = tr('profile.avatarUploadError'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr('profile.avatarTitle'),
                  style: AppTypography.display(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
              ),
              IconButton(
                key: const Key('avatar_close'),
                onPressed: _saving ? null : () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x),
                tooltip: tr('actions.close'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_file == null && _error == null)
            Center(
              child: ProfileAvatar(
                name: widget.profile.displayName,
                url: widget.profile.avatarUrl,
                size: 112,
              ),
            ),
          if (_file != null) ...[
            Text(
              tr('profile.avatarAdjust'),
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 13,
                color: colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ClipOval(
                child: RepaintBoundary(
                  key: _cropKey,
                  child: SizedBox.square(
                    dimension: 220,
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      boundaryMargin: const EdgeInsets.all(100),
                      child: Image.memory(
                        _file!.bytes,
                        key: const Key('avatar_preview'),
                        fit: BoxFit.cover,
                        width: 220,
                        height: 220,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: Image.memory(
                    _file!.bytes,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                ClipOval(
                  child: Image.memory(
                    _file!.bytes,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            AppCard(
              backgroundColor: colors.statusErrorBg,
              borderColor: colors.destructive.withValues(alpha: .2),
              child: Text(
                _error!,
                key: const Key('avatar_error'),
                style: AppTypography.body(
                  fontSize: 13,
                  color: colors.statusErrorFg,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            tr('profile.avatarHelper'),
            style: AppTypography.body(
              fontSize: 13,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  key: const Key('avatar_camera'),
                  text: tr('profile.takePhoto'),
                  icon: const Icon(LucideIcons.camera),
                  variant: AppButtonVariant.outline,
                  onPressed: _saving ? null : () => _pick(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  key: const Key('avatar_library'),
                  text: tr('profile.choosePhoto'),
                  icon: const Icon(LucideIcons.image),
                  variant: AppButtonVariant.outline,
                  onPressed: _saving ? null : () => _pick(ImageSource.gallery),
                ),
              ),
            ],
          ),
          if (_file != null) ...[
            const SizedBox(height: 12),
            AppButton(
              key: const Key('avatar_save'),
              text: tr('profile.savePhoto'),
              isFullWidth: true,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ],
      ),
    );
  }
}
