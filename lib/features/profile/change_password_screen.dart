import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../api/api_error.dart';
import '../../auth/token_storage.dart';
import '../../components/common/app_toast.dart';
import '../../components/layout/screen_scaffold.dart';
import '../../components/ui/app_button.dart';
import '../../components/ui/app_card.dart';
import '../../components/ui/app_input.dart';
import '../../components/ui/app_skeleton.dart';
import '../../config/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'profile_constants.dart';
import 'profile_providers.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _showCurrent = false;
  bool _showNext = false;
  bool _showConfirm = false;
  bool _saving = false;
  String? _currentError;
  String? _apiError;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _sameAsCurrent =>
      _next.text.isNotEmpty && _next.text == _current.text;

  bool get _confirmMismatch =>
      _confirm.text.isNotEmpty && _confirm.text != _next.text;

  bool get _canSave =>
      _current.text.isNotEmpty &&
      PasswordRules(_next.text).isValid &&
      !_sameAsCurrent &&
      _confirm.text == _next.text &&
      !_saving;

  void _changed() {
    setState(() {
      _currentError = null;
      _apiError = null;
    });
  }

  Widget _visibilityButton({
    required bool visible,
    required VoidCallback onPressed,
    required String keyName,
  }) => IconButton(
    key: Key(keyName),
    onPressed: onPressed,
    icon: Icon(visible ? LucideIcons.eyeOff : LucideIcons.eye),
    tooltip: tr(visible ? 'profile.hidePassword' : 'profile.showPassword'),
  );

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() {
      _saving = true;
      _currentError = null;
      _apiError = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref
          .read(profileRepositoryProvider)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
            confirmation: _confirm.text,
          );
      await ref
          .read(tokenStorageProvider)
          .saveTokens(result.tokens.accessToken, result.tokens.refreshToken);
      if (mounted) {
        context.go(AppRoutes.profile);
        showAppToast(messenger, tr('profile.passwordChanged'));
      }
    } on ApiError catch (error) {
      if (!mounted) return;
      if (error.code == 'CURRENT_CREDENTIAL_INVALID') {
        setState(() => _currentError = tr('profile.errors.currentPassword'));
      } else {
        setState(
          () => _apiError = error.code == 'RATE_LIMITED'
              ? tr('profile.errors.rateLimited')
              : tr('profile.errors.passwordGeneric'),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _apiError = tr('profile.errors.passwordGeneric'));
      }
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
        appBar: AppBar(title: Text(tr('profile.changePassword'))),
        body: const Column(
          children: [
            AppSkeleton(height: 76),
            SizedBox(height: 16),
            AppSkeleton(height: 76),
            SizedBox(height: 16),
            AppSkeleton(height: 76),
          ],
        ),
      );
    }
    if (!profile.canMutate || !profile.hasPassword) {
      return ScreenScaffold(
        appBar: AppBar(title: Text(tr('profile.changePassword'))),
        body: Center(child: Text(tr('profile.restricted.message'))),
      );
    }

    final rules = PasswordRules(_next.text);
    return ScreenScaffold(
      appBar: AppBar(title: Text(tr('profile.changePassword'))),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Text(
                  tr('profile.passwordHint'),
                  style: AppTypography.body(
                    fontSize: 14,
                    color: context.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 20),
                AppInput(
                  key: const Key('password_current'),
                  label: tr('profile.currentPassword'),
                  controller: _current,
                  obscureText: !_showCurrent,
                  errorText: _currentError,
                  suffixIcon: _visibilityButton(
                    visible: _showCurrent,
                    keyName: 'password_current_visibility',
                    onPressed: () =>
                        setState(() => _showCurrent = !_showCurrent),
                  ),
                  onChanged: (_) => _changed(),
                ),
                const SizedBox(height: 16),
                AppInput(
                  key: const Key('password_new'),
                  label: tr('profile.newPassword'),
                  controller: _next,
                  obscureText: !_showNext,
                  errorText: _sameAsCurrent
                      ? tr('profile.errors.samePassword')
                      : null,
                  suffixIcon: _visibilityButton(
                    visible: _showNext,
                    keyName: 'password_new_visibility',
                    onPressed: () => setState(() => _showNext = !_showNext),
                  ),
                  onChanged: (_) => _changed(),
                ),
                const SizedBox(height: 12),
                for (final item in [
                  (rules.length, 'profile.passwordRules.length'),
                  (rules.uppercase, 'profile.passwordRules.upper'),
                  (rules.lowercase, 'profile.passwordRules.lower'),
                  (rules.digit, 'profile.passwordRules.digit'),
                  (rules.special, 'profile.passwordRules.special'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${item.$1 ? '✓' : '○'} ${tr(item.$2)}',
                      style: AppTypography.body(
                        fontSize: 13,
                        color: item.$1
                            ? context.colors.statusSuccessFg
                            : context.colors.mutedForeground,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                AppInput(
                  key: const Key('password_confirm'),
                  label: tr('profile.confirmPassword'),
                  controller: _confirm,
                  obscureText: !_showConfirm,
                  errorText: _confirmMismatch
                      ? tr('profile.errors.confirm')
                      : null,
                  suffixIcon: _visibilityButton(
                    visible: _showConfirm,
                    keyName: 'password_confirm_visibility',
                    onPressed: () =>
                        setState(() => _showConfirm = !_showConfirm),
                  ),
                  onChanged: (_) => _changed(),
                ),
                if (_apiError != null) ...[
                  const SizedBox(height: 16),
                  AppCard(
                    key: const Key('password_api_error'),
                    backgroundColor: context.colors.statusErrorBg,
                    borderColor: context.colors.destructive.withValues(
                      alpha: .2,
                    ),
                    child: Text(
                      _apiError!,
                      style: AppTypography.body(
                        fontSize: 14,
                        color: context.colors.statusErrorFg,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: AppButton(
              key: const Key('password_save'),
              text: tr('profile.changePassword'),
              isFullWidth: true,
              isLoading: _saving,
              onPressed: _canSave ? _save : null,
            ),
          ),
        ],
      ),
    );
  }
}
