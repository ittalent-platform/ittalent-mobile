import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_error.dart';
import '../../auth/token_storage.dart';
import '../../components/common/app_toast.dart';
import '../../components/layout/screen_scaffold.dart';
import '../../components/ui/app_button.dart';
import '../../components/ui/app_input.dart';
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
  final _current = TextEditingController(),
      _next = TextEditingController(),
      _confirm = TextEditingController();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _clear() {
    _current.clear();
    _next.clear();
    _confirm.clear();
  }

  Future<void> _save() async {
    final rules = PasswordRules(_next.text);
    if (!rules.isValid ||
        _next.text == _current.text ||
        _next.text != _confirm.text) {
      return;
    }
    setState(() => _saving = true);
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
      _clear();
      if (mounted) {
        context.go('/profile');
        showAppToast(messenger, tr('profile.passwordChanged'));
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(
          () => _error = e.code == 'CURRENT_CREDENTIAL_INVALID'
              ? tr('profile.errors.currentPassword')
              : e.code == 'RATE_LIMITED'
              ? tr('profile.errors.rateLimited')
              : e.message,
        );
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
    if (profile?.canMutate != true || profile?.hasPassword != true) {
      return ScreenScaffold(
        appBar: AppBar(title: Text(tr('profile.changePassword'))),
        body: Center(child: Text(tr('profile.restricted.message'))),
      );
    }
    final rules = PasswordRules(_next.text);
    final canSave =
        _current.text.isNotEmpty &&
        rules.isValid &&
        _next.text != _current.text &&
        _next.text == _confirm.text &&
        !_saving;
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
                  label: tr('profile.currentPassword'),
                  controller: _current,
                  obscureText: true,
                  errorText: _error,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                AppInput(
                  label: tr('profile.newPassword'),
                  controller: _next,
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
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
                  label: tr('profile.confirmPassword'),
                  controller: _confirm,
                  obscureText: true,
                  errorText:
                      _confirm.text.isNotEmpty && _confirm.text != _next.text
                      ? tr('profile.errors.confirm')
                      : null,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: AppButton(
              text: tr('profile.changePassword'),
              isFullWidth: true,
              isLoading: _saving,
              onPressed: canSave ? _save : null,
            ),
          ),
        ],
      ),
    );
  }
}
