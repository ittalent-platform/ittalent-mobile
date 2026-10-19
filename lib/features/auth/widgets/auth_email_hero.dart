import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

class AuthEmailHero extends StatelessWidget {
  const AuthEmailHero({
    super.key,
    this.email,
    this.title = 'Check your email',
    this.instructionsPrefix,
    this.instructionsSuffix,
    this.plainSubtitle,
    this.badgeBgColor = const Color(0xFFFDE8E0),
    this.badgeIcon = const Icon(
      Icons.mail_outline_rounded,
      size: 34,
      color: Color(0xFFB33305),
    ),
  });

  final String? email;
  final String title;
  final String? instructionsPrefix;
  final String? instructionsSuffix;
  final String? plainSubtitle;
  final Color badgeBgColor;
  final Widget badgeIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Widget subtitleWidget;
    if (plainSubtitle != null && plainSubtitle!.isNotEmpty) {
      subtitleWidget = Text(
        plainSubtitle!,
        textAlign: TextAlign.center,
        style: AppTypography.body(
          fontSize: 15.5,
          color: colors.mutedForeground,
        ).copyWith(height: 1.55),
      );
    } else {
      final prefix = instructionsPrefix ?? 'We sent a verification link to ';
      final suffix =
          instructionsSuffix ?? '. Open it on this phone to finish signing up.';

      subtitleWidget = Text.rich(
        TextSpan(
          style: AppTypography.body(
            fontSize: 15.5,
            color: colors.mutedForeground,
          ).copyWith(height: 1.55),
          children: [
            TextSpan(text: prefix),
            if (email != null && email!.isNotEmpty)
              TextSpan(
                text: email!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.foreground,
                ),
              ),
            TextSpan(text: suffix),
          ],
        ),
        textAlign: TextAlign.center,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: badgeBgColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: badgeIcon,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.display(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 12),
            subtitleWidget,
          ],
        ),
      ),
    );
  }
}
