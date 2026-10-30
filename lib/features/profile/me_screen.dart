import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../auth/auth_notifier.dart';
import '../../components/layout/screen_scaffold.dart';
import '../../components/ui/app_card.dart';
import '../../components/ui/app_menu_group.dart';
import '../../components/ui/app_menu_tile.dart';
import '../../config/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../applicant/certificates/certificates_providers.dart';
import 'profile_providers.dart';
import 'widgets/profile_avatar.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(authNotifierProvider).user;
    final profile = ref.watch(profileProvider).value;
    final certificateCount = ref.watch(certificateCountProvider).value ?? 0;
    final authName = user?.fullName?.trim();
    final name =
        profile?.displayName ??
        ((authName?.isNotEmpty ?? false) ? authName! : user?.username.trim()) ??
        '';
    final email = profile?.email ?? user?.email.trim() ?? '';
    final canChangePassword =
        profile?.canMutate == true && profile?.hasPassword == true;

    return ScreenScaffold(
      padding: EdgeInsets.zero,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Text(
                tr('profile.me.title'),
                style: AppTypography.display(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                  color: colors.foreground,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                key: const Key('me_profile_card'),
                onTap: () => context.push(AppRoutes.profileDetails),
                child: Row(
                  children: [
                    ProfileAvatar(name: name, url: profile?.avatarUrl),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTypography.body(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.foreground,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              email,
                              style: AppTypography.body(
                                fontSize: 13.5,
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: colors.mutedForeground,
                    ),
                  ],
                ),
              ),
            ),
            AppMenuGroup(
              title: tr('profile.me.profileSection'),
              children: [
                AppMenuTile(
                  key: const Key('me_menu_profile'),
                  icon: LucideIcons.user,
                  title: tr('profile.title'),
                  onTap: () => context.push(AppRoutes.profileDetails),
                ),
                AppMenuTile(
                  key: const Key('me_menu_documents'),
                  icon: LucideIcons.fileText,
                  title: tr('accountNav.documents'),
                  onTap: () {},
                ),
                AppMenuTile(
                  key: const Key('me_menu_certificates'),
                  icon: LucideIcons.award,
                  title: tr('accountNav.certificates'),
                  badgeCount: certificateCount > 0 ? certificateCount : null,
                  onTap: () => context.push(AppRoutes.certificates),
                ),
                AppMenuTile(
                  key: const Key('me_menu_portfolio'),
                  icon: LucideIcons.link,
                  title: tr('profile.me.portfolio'),
                  showDivider: false,
                  onTap: () => context.push(AppRoutes.portfolio),
                ),
              ],
            ),
            AppMenuGroup(
              title: tr('profile.me.jobSearchSection'),
              children: [
                AppMenuTile(
                  key: const Key('me_menu_saved_jobs'),
                  icon: LucideIcons.heart,
                  title: tr('profile.me.savedJobs'),
                  trailingChevron: false,
                  onTap: null,
                ),
                AppMenuTile(
                  key: const Key('me_menu_my_reports'),
                  icon: LucideIcons.flag,
                  title: tr('profile.me.myReports'),
                  trailingChevron: false,
                  showDivider: false,
                  onTap: null,
                ),
              ],
            ),
            AppMenuGroup(
              title: tr('profile.me.accountSection'),
              children: [
                AppMenuTile(
                  key: const Key('me_menu_notifications'),
                  icon: LucideIcons.bell,
                  title: tr('notifications.title'),
                  onTap: () => context.push(AppRoutes.notifications),
                ),
                AppMenuTile(
                  key: const Key('me_menu_password'),
                  icon: LucideIcons.key,
                  title: tr('profile.me.password'),
                  trailingChevron: canChangePassword,
                  onTap: canChangePassword
                      ? () => context.push(AppRoutes.changePassword)
                      : null,
                ),
                AppMenuTile(
                  key: const Key('me_menu_sign_out'),
                  icon: LucideIcons.logOut,
                  title: tr('profile.me.signOut'),
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
