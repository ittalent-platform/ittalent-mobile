import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../auth/auth_notifier.dart';
import '../../components/layout/screen_scaffold.dart';
import '../../components/ui/app_menu_group.dart';
import '../../components/ui/app_menu_tile.dart';
import '../../config/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    final String fullName;
    if (user != null &&
        user.fullName != null &&
        user.fullName!.trim().isNotEmpty) {
      fullName = user.fullName!.trim();
    } else if (user != null && user.username.trim().isNotEmpty) {
      fullName = user.username.trim();
    } else {
      fullName = 'Nguyễn Văn An';
    }

    final String email = (user != null && user.email.trim().isNotEmpty)
        ? user.email.trim()
        : 'an.nguyen@gmail.com';

    return ScreenScaffold(
      padding: EdgeInsets.zero,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Text(
                'Me',
                style: AppTypography.display(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                  color: const Color(0xFF19191C),
                ),
              ),
            ),

            // Profile Summary Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE6E4DF), width: 1.0),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Avatar Circle
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment(-0.64, -0.77),
                              end: Alignment(0.64, 0.77),
                              colors: [Color(0xFFF2A07B), Color(0xFFC8501F)],
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          alignment: Alignment.bottomCenter,
                          child: CustomPaint(
                            size: const Size(46, 46),
                            painter: _CandidateAvatarPainter(),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Identity Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: AppTypography.body(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF19191C),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Project manager · Agile delivery',
                                style: AppTypography.body(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF64646B),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                email,
                                style: AppTypography.body(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF64646B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Trailing Chevron
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: Color(0xFFB9B8B4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // MY PROFILE Section
            AppMenuGroup(
              title: 'MY PROFILE',
              children: [
                AppMenuTile(
                  key: const Key('me_menu_profile'),
                  icon: LucideIcons.user,
                  title: 'Profile',
                  onTap: () {},
                ),
                AppMenuTile(
                  key: const Key('me_menu_documents'),
                  icon: LucideIcons.fileText,
                  title: 'Documents',
                  badgeCount: 4,
                  onTap: () {},
                ),
                AppMenuTile(
                  key: const Key('me_menu_certificates'),
                  icon: LucideIcons.award,
                  title: 'Certificates',
                  badgeCount: 5,
                  onTap: () => context.push(AppRoutes.certificates),
                ),
                AppMenuTile(
                  key: const Key('me_menu_portfolio'),
                  icon: LucideIcons.link,
                  title: 'Portfolio',
                  showDivider: false,
                  onTap: () {},
                ),
              ],
            ),

            // JOB SEARCH Section
            AppMenuGroup(
              title: 'JOB SEARCH',
              children: [
                AppMenuTile(
                  key: const Key('me_menu_saved_jobs'),
                  icon: LucideIcons.heart,
                  title: 'Saved jobs',
                  badgeCount: 6,
                  onTap: () {},
                ),
                AppMenuTile(
                  key: const Key('me_menu_my_reports'),
                  icon: LucideIcons.flag,
                  title: 'My reports',
                  showDivider: false,
                  onTap: () {},
                ),
              ],
            ),

            // ACCOUNT Section
            AppMenuGroup(
              title: 'ACCOUNT',
              children: [
                AppMenuTile(
                  key: const Key('me_menu_notifications'),
                  icon: LucideIcons.bell,
                  title: 'Notifications',
                  onTap: () {},
                ),
                AppMenuTile(
                  key: const Key('me_menu_password'),
                  icon: LucideIcons.key,
                  title: 'Password',
                  onTap: () {},
                ),
                AppMenuTile(
                  key: const Key('me_menu_sign_out'),
                  icon: LucideIcons.logOut,
                  title: 'Sign out',
                  isDestructive: true,
                  showDivider: false,
                  onTap: () {
                    ref.read(authNotifierProvider.notifier).logout();
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CandidateAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFBE3D6)
      ..style = PaintingStyle.fill;

    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    // Head circle cx="12" cy="8" r="4.2"
    canvas.drawCircle(const Offset(12, 8), 4.2, paint);

    // Shoulders path: M3.5 23c.6-5 4-8 8.5-8s7.9 3 8.5 8z
    final path = Path()
      ..moveTo(3.5, 23)
      ..cubicTo(4.1, 18, 7.5, 15, 12, 15)
      ..cubicTo(16.5, 15, 19.9, 18, 20.5, 23)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
