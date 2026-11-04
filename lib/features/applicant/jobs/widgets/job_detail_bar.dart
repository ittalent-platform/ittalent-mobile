import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/ui/app_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';

/// What the sticky bar of a job page offers.
enum JobAction { apply, signIn, applied, closed }

/// The bar at the bottom of a job page: one button that says what the
/// applicant can do with the job, and the bookmark that saves it. A job that
/// no longer takes applications has no Apply button, and sends the applicant
/// to similar jobs.
class JobDetailBar extends StatelessWidget {
  const JobDetailBar({
    super.key,
    required this.action,
    required this.onPressed,
    this.onSave,
    this.saved = false,
    this.saving = false,
  });

  final JobAction action;
  final VoidCallback onPressed;

  /// Saves the job, or takes it out of the saved ones; null leaves the
  /// bookmark out.
  final VoidCallback? onSave;
  final bool saved;

  /// A save or removal is on its way: the bookmark waits for it.
  final bool saving;

  /// The bookmark is a square as high as the button next to it.
  static const double saveSize = 50;
  static const double saveGap = 12;

  Widget _save(BuildContext context) {
    final colors = context.colors;
    final label = tr(saved ? 'jobs.detail.unsave' : 'jobs.detail.save');
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      // The node says what the bookmark is and that it can be activated: with
      // the children excluded, the tap of the InkWell would not reach
      // TalkBack ("clickable" off) unless it is given here.
      child: Semantics(
        button: true,
        selected: saved,
        label: label,
        onTap: saving ? null : onSave,
        excludeSemantics: true,
        child: Material(
          color: saved ? colors.muted : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
            side: BorderSide(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: saving ? null : onSave,
            child: SizedBox(
              width: saveSize,
              height: saveSize,
              child: Icon(
                saved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                size: 20,
                color: saved ? colors.primary : colors.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }

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
      child: SafeArea(
        top: false,
        child: onSave == null
            ? button
            : Row(
                children: [
                  _save(context),
                  const SizedBox(width: saveGap),
                  Expanded(child: button),
                ],
              ),
      ),
    );
  }
}
