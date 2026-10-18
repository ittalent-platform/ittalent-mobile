import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/ui/app_button.dart';
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../widgets/auth_footer_note.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.primary,
      body: Stack(
        children: [
          // Background concentric decorative curves
          Positioned(
            bottom: 220,
            left: -100,
            right: -100,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 520,
                    height: 520,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                  Container(
                    width: 380,
                    height: 380,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Monogram and Brand Wordmark
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  LucideIcons.userRound,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ITTALENT',
                              style: AppTypography.body(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        // Hero Headline
                        Text(
                          'Where IT careers\ntake shape.',
                          style: AppTypography.display(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Value proposition check items
                        _buildCheckItem('Jobs from verified IT companies'),
                        const SizedBox(height: 14),
                        _buildCheckItem('One CV for every application'),
                        const SizedBox(height: 14),
                        _buildCheckItem('Track each application in one place'),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom Action Panel
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton(
                        text: 'Create account',
                        size: AppButtonSize.lg,
                        isFullWidth: true,
                        onPressed: () => context.push(AppRoutes.register),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        text: 'Sign in',
                        variant: AppButtonVariant.secondary,
                        size: AppButtonSize.lg,
                        isFullWidth: true,
                        onPressed: () => context.push(AppRoutes.login),
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.jobs),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Browse jobs first',
                              style: AppTypography.body(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              LucideIcons.arrowRight,
                              size: 16,
                              color: colors.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const AuthFooterNote(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          child: const Center(
            child: Icon(LucideIcons.check, size: 13, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
