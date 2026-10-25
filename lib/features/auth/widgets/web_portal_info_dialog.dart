import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../components/ui/app_badge.dart';
import '../../../components/ui/app_button.dart';
import '../../../config/env.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_typography.dart';

typedef UrlLauncherFn = Future<bool> Function(Uri uri, {LaunchMode mode});

class WebPortalInfoDialog extends StatelessWidget {
  const WebPortalInfoDialog({super.key, this.role, this.launcher});

  final String? role;
  final UrlLauncherFn? launcher;

  String _formatRoleLabel(String? role) {
    if (role == null) return 'Web Account';
    switch (role.toLowerCase()) {
      case 'recruiter':
        return 'Recruiter Account';
      case 'enterprise_admin':
        return 'Enterprise Admin Account';
      case 'admin':
        return 'Platform Admin Account';
      default:
        return 'Staff Account';
    }
  }

  Future<void> _handleGoToWeb(BuildContext context) async {
    Navigator.of(context).pop();
    final uri = Uri.parse(AppEnv.webBaseUrl);
    final fn = launcher ?? launchUrl;
    try {
      await fn(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Ignore URL launch failures silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.card,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: BorderSide(color: colors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.globe,
                    color: colors.primary,
                    size: 18,
                  ),
                ),
                const Spacer(),
                AppBadge(label: _formatRoleLabel(role), tone: BadgeTone.peach),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Web Portal Required',
              style: AppTypography.display(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'This mobile app is for job applicants only. Recruiter and Admin accounts must log in via the web portal.',
              style: AppTypography.body(
                fontSize: 13,
                color: colors.mutedForeground,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Dismiss',
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.sm,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    text: 'Open Web',
                    icon: const Icon(LucideIcons.externalLink, size: 14),
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.sm,
                    onPressed: () => _handleGoToWeb(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
