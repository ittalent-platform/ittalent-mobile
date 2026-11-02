import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/ui/app_button.dart';
import '../../../../theme/app_colors.dart';

/// What the sticky bar of a job page offers.
enum JobAction { apply, signIn, applied, closed }

/// The bar at the bottom of a job page: one button that says what the
/// applicant can do with the job. A job that no longer takes applications
/// has no Apply button, and sends the applicant to similar jobs.
class JobDetailBar extends StatelessWidget {
  const JobDetailBar({
    super.key,
    required this.action,
    required this.onPressed,
  });

  final JobAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final button = switch (action) {
      JobAction.apply => AppButton(
        text: tr('jobs.detail.apply'),
        isFullWidth: true,
        size: AppButtonSize.lg,
        onPressed: onPressed,
      ),
      JobAction.signIn => AppButton(
        text: tr('jobs.detail.signInToApply'),
        icon: const Icon(LucideIcons.lock),
        isFullWidth: true,
        size: AppButtonSize.lg,
        onPressed: onPressed,
      ),
      JobAction.applied => AppButton(
        text: tr('jobs.detail.applied'),
        icon: const Icon(LucideIcons.circleCheck),
        variant: AppButtonVariant.outline,
        isFullWidth: true,
        size: AppButtonSize.lg,
        onPressed: onPressed,
      ),
      JobAction.closed => AppButton(
        text: tr('jobs.detail.seeSimilar'),
        variant: AppButtonVariant.outline,
        isFullWidth: true,
        size: AppButtonSize.lg,
        onPressed: onPressed,
      ),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(top: false, child: button),
    );
  }
}
