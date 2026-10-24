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
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: BorderSide(color: colors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.globe,
                    color: colors.primary,
                    size: 24,
                  ),
                ),
                const Spacer(),
                AppBadge(label: _formatRoleLabel(role), tone: BadgeTone.peach),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Web Portal Required',
              style: AppTypography.display(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This mobile app is exclusively for job applicants. Recruiter and Administrator accounts must manage job postings, interviews, and candidates via the ITTalent web portal.',
              style: AppTypography.body(
                fontSize: 14,
                color: colors.mutedForeground,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Go to Web',
              icon: const Icon(LucideIcons.externalLink, size: 16),
              variant: AppButtonVariant.primary,
              isFullWidth: true,
              onPressed: () => _handleGoToWeb(context),
            ),
            const SizedBox(height: 10),
            AppButton(
              text: 'Dismiss',
              variant: AppButtonVariant.outline,
              isFullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
