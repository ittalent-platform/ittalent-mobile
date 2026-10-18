import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/ui/app_button.dart';
import '../../../components/ui/ittalent_monogram.dart';
import '../../../config/routes.dart';
import '../../../theme/app_typography.dart';
import '../widgets/auth_footer_note.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top Hero Area with solid #D23D05 background and concentric filled disks
          Expanded(
            child: Container(
              color: const Color(0xFFD23D05),
              child: CustomPaint(
                painter: const _HeroConcentricDisksPainter(),
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
                            const ITTalentMonogram(size: 26),
                            const SizedBox(width: 8),
                            Text(
                              'ITTALENT',
                              style: AppTypography.display(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.04 * 15,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        // Hero Headline
                        Text(
                          'Where IT careers\ntake shape.',
                          style: AppTypography.display(
                            fontSize: 38,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.06,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Value proposition check items
                        _buildCheckItem('Jobs from verified IT companies'),
                        const SizedBox(height: 12),
                        _buildCheckItem('One CV for every application'),
                        const SizedBox(height: 12),
                        _buildCheckItem('Track each application in one place'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bottom Action Panel
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
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
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.jobs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Browse jobs first',
                          style: AppTypography.body(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFB33305),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          LucideIcons.arrowRight,
                          size: 16,
                          color: Color(0xFFB33305),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const AuthFooterNote(),
                ],
              ),
            ),
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

class _HeroConcentricDisksPainter extends CustomPainter {
  const _HeroConcentricDisksPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);

    // Circles are centered at the horizontal center and bottom edge of the hero
    final center = Offset(size.width / 2, size.height);

    // 5 concentric filled disks from outermost to innermost
    final disks = const [
      (280.0, Color(0xFFE85A1F)),
      (220.0, Color(0xFFEE6C34)),
      (165.0, Color(0xFFF3834F)),
      (115.0, Color(0xFFF79C70)),
      (70.0, Color(0xFFFAB796)),
    ];

    for (final (radius, color) in disks) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
