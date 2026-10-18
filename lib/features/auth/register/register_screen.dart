import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../auth/auth_dto.dart';
import '../../../auth/auth_notifier.dart';
import '../../../components/ui/app_button.dart';
import '../../../components/ui/app_checkbox.dart';
import '../../../components/ui/app_input.dart';
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../widgets/auth_error_banner.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;

  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _termsError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _termsError = null;
    });

    bool isValid = true;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      setState(() => _nameError = 'Full name is required');
      isValid = false;
    } else if (name.length < 2) {
      setState(() => _nameError = 'Full name must be at least 2 characters');
      isValid = false;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      isValid = false;
    } else if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      isValid = false;
    }

    if (phone.isNotEmpty) {
      final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
      if (!phoneRegex.hasMatch(phone.replaceAll(RegExp(r'\s+'), ''))) {
        setState(() => _phoneError = 'Mobile must be 10–15 digits');
        isValid = false;
      }
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      isValid = false;
    } else if (password.length < 8 || password.length > 64) {
      setState(() => _passwordError = 'Password must be 8–64 characters');
      isValid = false;
    } else if (!password.contains(RegExp(r'[A-Z]'))) {
      setState(
        () => _passwordError = 'Password must contain an uppercase letter',
      );
      isValid = false;
    } else if (!password.contains(RegExp(r'[a-z]'))) {
      setState(
        () => _passwordError = 'Password must contain a lowercase letter',
      );
      isValid = false;
    } else if (!password.contains(RegExp(r'[0-9]'))) {
      setState(() => _passwordError = 'Password must contain a number');
      isValid = false;
    } else if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      setState(
        () => _passwordError = 'Password must contain a special character',
      );
      isValid = false;
    }

    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Please confirm your password');
      isValid = false;
    } else if (password != confirmPassword) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      isValid = false;
    }

    if (!_termsAccepted) {
      setState(() => _termsError = 'You must agree to the Terms and Privacy');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleSubmit() async {
    if (!_validateForm()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    var prefix = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    if (prefix.length < 3) {
      prefix = '${prefix}_usr';
    }
    if (prefix.length > 30) {
      prefix = prefix.substring(0, 30);
    }

    final success = await ref
        .read(authNotifierProvider.notifier)
        .register(
          RegisterRequest(email: email, username: prefix, password: password),
        );

    if (success && mounted) {
      context.go(
        '${AppRoutes.verifyEmailNotice}?email=${Uri.encodeComponent(email)}',
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
                vertical: 12.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24.0,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            context.go(AppRoutes.welcome);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Create your account',
                        style: AppTypography.display(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign up as a candidate. We’ll email you a link to verify your address.',
                        style: AppTypography.body(
                          fontSize: 15.5,
                          color: colors.mutedForeground,
                          height: 1.5,
                        ),
                      ),
                      if (authState.errorMessage != null &&
                          authState.errorMessage!.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        AuthErrorBanner(
                          message: authState.errorMessage!,
                          tone: AuthBannerTone.error,
                        ),
                      ],
                      const SizedBox(height: 20),
                      AppInput(
                        controller: _nameController,
                        label: 'Full name',
                        isRequired: true,
                        hintText: 'Nguyễn Văn An',
                        errorText: _nameError,
                        onChanged: (_) {
                          if (_nameError != null) {
                            setState(() => _nameError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
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
                        },
                      ),
                      const SizedBox(height: 14),
                      AppInput(
                        controller: _phoneController,
                        label: 'Mobile',
                        hintText: '0901 234 567',
                        helperText: 'Optional · 10–15 digits',
                        keyboardType: TextInputType.phone,
                        errorText: _phoneError,
                        onChanged: (_) {
                          if (_phoneError != null) {
                            setState(() => _phoneError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      AppInput(
                        controller: _passwordController,
                        label: 'Password',
                        isRequired: true,
                        hintText: '••••••••••',
                        obscureText: _obscurePassword,
                        helperText: '8–64 characters with upper and lower case, a number and a special character.',
                        errorText: _passwordError,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? LucideIcons.eye
                                : LucideIcons.eyeOff,
                            size: 20,
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
                      const SizedBox(height: 14),
                      AppInput(
                        controller: _confirmPasswordController,
                        label: 'Confirm password',
                        isRequired: true,
                        hintText: '••••••••••',
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
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      AppCheckbox(
                        value: _termsAccepted,
                        hasError: _termsError != null,
                        onChanged: (val) {
                          setState(() {
                            _termsAccepted = val ?? false;
                            if (_termsAccepted) _termsError = null;
                          });
                        },
                        child: Text.rich(
                          TextSpan(
                            style: AppTypography.body(
                              fontSize: 14.5,
                              color: colors.foreground,
                            ).copyWith(height: 1.45),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms of use',
                                style: TextStyle(
                                  color: colors.fgLink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy policy',
                                style: TextStyle(
                                  color: colors.fgLink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),
                      if (_termsError != null) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: Text(
                            _termsError!,
                            style: AppTypography.body(
                              fontSize: 13,
                              color: colors.destructive,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      AppButton(
                        text: 'Create account',
                        size: AppButtonSize.lg,
                        isFullWidth: true,
                        isLoading: authState.isLoading,
                        onPressed: _handleSubmit,
                      ),
                      const Spacer(),
                      const SizedBox(height: 20),
                      Center(
                        child: Text.rich(
                          TextSpan(
                            style: AppTypography.body(
                              fontSize: 15,
                              color: colors.mutedForeground,
                            ),
                            children: [
                              const TextSpan(text: 'Already have an account? '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: GestureDetector(
                                  onTap: () => context.go(AppRoutes.login),
                                  child: Text(
                                    'Sign in',
                                    style: AppTypography.body(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: colors.fgLink,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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
