import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../auth/auth_notifier.dart';
import '../../../components/ui/app_button.dart';
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../widgets/auth_email_hero.dart';
import '../widgets/auth_error_banner.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({
    super.key,
    this.token,
    this.email,
    this.initialVerified = false,
  });

  final String? token;
  final String? email;
  final bool initialVerified;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  late bool _isVerified;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isVerified = widget.initialVerified;
  }

  Future<void> _handleVerify() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'This verification link is no longer valid.';
      });
      return;
    }

    if (kDebugMode && token == 'dev-mock-valid') {
      setState(() {
        _isVerified = true;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(authNotifierProvider.notifier)
        .verifyEmail(token);

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
      if (success) {
        _isVerified = true;
        _errorMessage = null;
      } else {
        final authState = ref.read(authNotifierProvider);
        _errorMessage =
            authState.errorMessage ??
            'This verification link is no longer valid.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentEmail = (widget.email != null && widget.email!.isNotEmpty)
        ? widget.email!
        : 'an.nguyen@gmail.com';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      if (_errorMessage != null && !_isVerified) ...[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFDE8E0),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.error_outline_rounded,
                                    size: 34,
                                    color: Color(0xFFB33305),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Invalid or expired link',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.display(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: colors.foreground,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AuthErrorBanner(
                                  message: _errorMessage!,
                                  tone: AuthBannerTone.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'This link has expired or has already been used. Please request a new verification link.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.body(
                                    fontSize: 15.5,
                                    color: colors.mutedForeground,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          child: AppButton(
                            text: 'Resend link',
                            variant: AppButtonVariant.primary,
                            size: AppButtonSize.lg,
                            isFullWidth: true,
                            onPressed: () {
                              context.go(
                                '${AppRoutes.verifyEmailNotice}?email=${Uri.encodeComponent(currentEmail)}',
                              );
                            },
                          ),
                        ),
                      ] else if (_isVerified) ...[
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: AuthEmailHero(
                              badgeBgColor: Color(0xFFE8F5EE),
                              badgeIcon: Icon(
                                Icons.check_circle_outline,
                                size: 34,
                                color: Color(0xFF12764A),
                              ),
                              title: 'Email verified',
                              plainSubtitle: 'Your account is ready. Sign in to start applying.',
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          child: AppButton(
                            text: 'Sign in',
                            variant: AppButtonVariant.primary,
                            size: AppButtonSize.lg,
                            isFullWidth: true,
                            onPressed: () => context.go(AppRoutes.login),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: AuthEmailHero(
                              badgeBgColor: const Color(0xFFE4ECFB),
                              badgeIcon: const Icon(
                                LucideIcons.shield,
                                size: 34,
                                color: Color(0xFF2A55A8),
                              ),
                              title: 'Verify your email',
                              instructionsPrefix: 'Confirm that ',
                              email: currentEmail,
                              instructionsSuffix: ' is yours. Opening the link alone doesn’t verify it.',
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          child: AppButton(
                            text: 'Verify email',
                            variant: AppButtonVariant.primary,
                            size: AppButtonSize.lg,
                            isFullWidth: true,
                            isLoading: _isVerifying,
                            onPressed: _handleVerify,
                          ),
                        ),
                      ],
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
