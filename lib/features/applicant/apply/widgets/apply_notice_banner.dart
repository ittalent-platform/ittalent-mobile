import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../apply_models.dart';

/// A message of the flow, in the colours of its tone: red for what went
/// wrong, amber for what is not allowed, blue for what is good to know.
class ApplyNoticeBanner extends StatelessWidget {
  const ApplyNoticeBanner({super.key, required this.notice});

  final ApplyNotice notice;

  static const double radius = 12;
  static const double iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground, outline, icon) = switch (notice.tone) {
      ApplyNoticeTone.error => (
        colors.statusErrorBg,
        colors.statusErrorFg,
        colors.destructive.withValues(alpha: 0.2),
        notice.offline ? LucideIcons.wifiOff : LucideIcons.triangleAlert,
      ),
      ApplyNoticeTone.warning => (
        colors.statusWarningBg,
        colors.statusWarningFg,
        colors.statusWarningBorder,
        LucideIcons.lock,
      ),
      ApplyNoticeTone.info => (
        colors.statusInfoBg,
        colors.statusInfoFg,
        colors.statusInfoBorder,
        LucideIcons.info,
      ),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: outline, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: iconSize, color: foreground),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr(notice.key, namedArgs: notice.args),
                style: AppTypography.body(
                  fontSize: 14,
                  height: 1.45,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
