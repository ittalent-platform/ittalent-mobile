import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../auth/auth_notifier.dart';
import '../../../components/ui/app_button.dart';
import '../../../components/ui/app_input.dart';
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/password_criteria_chips.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.token,
    this.email,
    this.skipTokenValidationForTesting = false,
  });

  final String token;
  final String? email;
  final bool skipTokenValidationForTesting;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isValidatingToken = true;
  bool _isTokenValid = false;
  String? _tokenError;

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String? _confirmPasswordError;
  String? _apiError;
  bool _isSubmitting = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    if (widget.skipTokenValidationForTesting) {
      _isValidatingToken = false;
      _isTokenValid = true;
    } else {
      _validateToken();
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _validateToken() async {
    if (widget.token.isEmpty) {
      setState(() {
        _isValidatingToken = false;
        _isTokenValid = false;
        _tokenError = 'This link isn’t valid';
      });
      return;
    }

    final res = await ref
        .read(authNotifierProvider.notifier)
        .validateResetToken(widget.token);

    if (!mounted) return;

    setState(() {
      _isValidatingToken = false;
      _isTokenValid = res.valid;
      if (!res.valid) {
        _tokenError =
            res.message ?? 'This verification link is no longer valid.';
      }
    });
  }

  Future<void> _handleReset() async {
    setState(() {
      _confirmPasswordError = null;
      _apiError = null;
    });

    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (!PasswordCriteriaChips.allCriteriaMet(newPassword)) {
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _confirmPasswordError = 'Passwords don’t match.';
      });
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await ref
        .read(authNotifierProvider.notifier)
        .resetPassword(widget.token, newPassword);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      setState(() => _isSuccess = true);
    } else {
      final authState = ref.read(authNotifierProvider);
      setState(() {
        _apiError =
            authState.errorMessage ??
            'Failed to reset password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isValidatingToken) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isSuccess) {
      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5EE),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 38,
                    color: Color(0xFF12764A),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Password changed',
                  textAlign: TextAlign.center,
                  style: AppTypography.display(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Password changed. Sign in with your new password.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    fontSize: 15.5,
                    color: colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: 'Sign in',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.lg,
                  isFullWidth: true,
                  onPressed: () => context.go(AppRoutes.login),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isTokenValid) {
      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  alignment: Alignment.centerLeft,
                  icon: Icon(
                    LucideIcons.chevronLeft,
                    size: 24,
                    color: colors.foreground,
                  ),
                  onPressed: () => context.go(AppRoutes.login),
                ),
                const SizedBox(height: 12),
                Text(
                  'Invalid link',
                  style: AppTypography.display(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 16),
                AuthErrorBanner(
                  message: _tokenError ?? 'This link isn’t valid',
                  tone: AuthBannerTone.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'One message for every bad link, so nothing about the account is revealed. Please request a new link to reset your password.',
                  style: AppTypography.body(
                    fontSize: 15.5,
                    color: colors.mutedForeground,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Request a new link',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.lg,
                  isFullWidth: true,
                  onPressed: () => context.go(AppRoutes.forgotPassword),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;
    final allCriteriaMet = PasswordCriteriaChips.allCriteriaMet(newPass);
    final isMatching = confirmPass.isNotEmpty && newPass == confirmPass;
    final canSubmit = allCriteriaMet && isMatching && !_isSubmitting;

    final subtitle = (widget.email != null && widget.email!.isNotEmpty)
        ? 'For ${widget.email}. You’ll sign in with it next time.'
        : 'Enter your new password. You’ll sign in with it next time.';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        alignment: Alignment.centerLeft,
                        icon: Icon(
                          LucideIcons.chevronLeft,
                          size: 24,
                          color: colors.foreground,
                        ),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.login);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Set a new password',
                        style: AppTypography.display(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: AppTypography.body(
                          fontSize: 15.5,
                          color: colors.mutedForeground,
                          height: 1.5,
                        ),
                      ),
                      if (_apiError != null && _apiError!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        AuthErrorBanner(
                          message: _apiError!,
                          tone: AuthBannerTone.error,
                        ),
                      ],
                      const SizedBox(height: 24),
                      AppInput(
                        controller: _newPasswordController,
                        label: 'New password',
                        isRequired: true,
                        hintText: '••••••••••',
                        obscureText: _obscureNewPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword
                                ? LucideIcons.eye
                                : LucideIcons.eyeOff,
                            size: 20,
                            color: colors.mutedForeground,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscureNewPassword = !_obscureNewPassword,
                            );
                          },
                        ),
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      PasswordCriteriaChips(password: newPass),
                      const SizedBox(height: 16),
                      AppInput(
                        controller: _confirmPasswordController,
                        label: 'Confirm new password',
                        isRequired: true,
                        hintText: 'Repeat the new password',
                        obscureText: _obscureConfirmPassword,
                        errorText: _confirmPasswordError,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? LucideIcons.eye
                                : LucideIcons.eyeOff,
                            size: 20,
                            color: colors.mutedForeground,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            );
                          },
                        ),
                        onChanged: (_) {
                          if (_confirmPasswordError != null) {
                            setState(() => _confirmPasswordError = null);
                          } else {
                            setState(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: 'Save new password',
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.lg,
                        isFullWidth: true,
                        isLoading: _isSubmitting,
                        onPressed: canSubmit ? _handleReset : null,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
