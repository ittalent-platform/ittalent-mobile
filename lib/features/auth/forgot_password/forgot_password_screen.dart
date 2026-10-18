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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _emailError;
  String? _apiError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validateEmail() {
    final value = _emailController.text.trim();
    if (value.isEmpty) {
      setState(() => _emailError = 'Email is required');
      return false;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      setState(() => _emailError = 'Please enter a valid email address');
      return false;
    }

    setState(() => _emailError = null);
    return true;
  }

  Future<void> _handleSubmit() async {
    setState(() => _apiError = null);

    if (!_validateEmail()) {
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final success = await ref
        .read(authNotifierProvider.notifier)
        .forgotPassword(email);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      context.go(
        '${AppRoutes.resetLinkSent}?email=${Uri.encodeComponent(email)}',
      );
    } else {
      final authState = ref.read(authNotifierProvider);
      setState(() {
        _apiError =
            authState.errorMessage ??
            'Failed to send reset link. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
                  child: Form(
                    key: _formKey,
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
                          'Forgot password?',
                          style: AppTypography.display(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter the email you signed up with. We’ll send a link to set a new password.',
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
                          controller: _emailController,
                          label: 'Email',
                          isRequired: true,
                          hintText: 'an.nguyen@gmail.com',
                          keyboardType: TextInputType.emailAddress,
                          errorText: _emailError,
                          onChanged: (_) {
                            if (_emailError != null) {
                              setState(() => _emailError = null);
                            }
                            if (_apiError != null) {
                              setState(() => _apiError = null);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        AppButton(
                          text: 'Send reset link',
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.lg,
                          isFullWidth: true,
                          isLoading: _isLoading,
                          onPressed: _handleSubmit,
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: GestureDetector(
                              onTap: () => context.go(AppRoutes.login),
                              child: Text(
                                'Back to sign in',
                                style: AppTypography.body(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFB33305),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
