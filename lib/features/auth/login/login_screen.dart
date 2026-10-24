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
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_footer_note.dart';
import '../widgets/web_portal_info_dialog.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _identifierError;
  String? _passwordError;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _identifierError = null;
      _passwordError = null;
    });

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    bool hasError = false;

    if (identifier.isEmpty) {
      setState(() => _identifierError = 'Email is required');
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      hasError = true;
    }

    if (hasError) return;

    final result = await ref
        .read(authNotifierProvider.notifier)
        .login(identifier, password);

    if (!mounted) return;

    if (result.isWebRoleNotSupported) {
      _passwordController.clear();
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => WebPortalInfoDialog(role: result.role),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32.0,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const AuthBrandHeader(
                        title: 'Welcome back',
                        subtitle: 'Sign in to your ITTalent candidate account.',
                      ),
                      if (authState.errorMessage != null &&
                          authState.errorMessage!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        AuthErrorBanner(
                          message: authState.errorMessage!,
                          tone:
                              authState.errorMessage!.toLowerCase().contains(
                                'verify',
                              )
                              ? AuthBannerTone.warning
                              : authState.errorMessage!.toLowerCase().contains(
                                  'attempt',
                                )
                              ? AuthBannerTone.info
                              : AuthBannerTone.error,
                          actionLabel:
                              authState.errorMessage!.toLowerCase().contains(
                                'verify',
                              )
                              ? 'Resend link'
                              : null,
                          onAction:
                              authState.errorMessage!.toLowerCase().contains(
                                'verify',
                              )
                              ? () {
                                  final email = _identifierController.text
                                      .trim();
                                  if (email.isNotEmpty) {
                                    ref
                                        .read(authNotifierProvider.notifier)
                                        .resendVerificationEmail(email);
                                  }
                                }
                              : null,
                        ),
                      ],
                      const SizedBox(height: 24),
                      AppInput(
                        controller: _identifierController,
                        label: 'Email',
                        hintText: 'an.nguyen@gmail.com',
                        keyboardType: TextInputType.emailAddress,
                        errorText: _identifierError,
                        onChanged: (_) {
                          if (_identifierError != null) {
                            setState(() => _identifierError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      AppInput(
                        controller: _passwordController,
                        label: 'Password',
                        hintText: '••••••••',
                        obscureText: _obscurePassword,
                        errorText: _passwordError,
                        labelTrailing: GestureDetector(
                          onTap: () => context.push(AppRoutes.forgotPassword),
                          child: Text(
                            'Forgot password?',
                            style: AppTypography.body(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.fgLink,
                            ),
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? LucideIcons.eye
                                : LucideIcons.eyeOff,
                            size: 18,
                            color: colors.mutedForeground,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                        onChanged: (_) {
                          if (_passwordError != null) {
                            setState(() => _passwordError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: 'Sign in',
                        size: AppButtonSize.lg,
                        isFullWidth: true,
                        isLoading: authState.isLoading,
                        onPressed: _handleSubmit,
                      ),
                      const SizedBox(height: 24),
                      const AuthDivider(text: 'New to ITTalent?'),
                      const SizedBox(height: 20),
                      AppButton(
                        text: 'Create a candidate account',
                        variant: AppButtonVariant.outline,
                        size: AppButtonSize.lg,
                        isFullWidth: true,
                        onPressed: () => context.push(AppRoutes.register),
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      const AuthFooterNote(),
                      const SizedBox(height: 8),
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
