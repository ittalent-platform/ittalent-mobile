import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

class AuthEmailHero extends StatelessWidget {
  const AuthEmailHero({
    super.key,
    required this.email,
    this.title = 'Check your email',
    this.instructionsPrefix = 'We sent a verification link to ',
    this.instructionsSuffix = '. Open it on this phone to finish signing up.',
  });

  final String email;
  final String title;
  final String instructionsPrefix;
  final String instructionsSuffix;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
              decoration: const BoxDecoration(
                color: Color(0xFFFDE8E0),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.mail_outline_rounded,
                size: 34,
                color: Color(0xFFB33305),
              ),
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
            Text.rich(
              TextSpan(
                style: AppTypography.body(
                  fontSize: 15.5,
                  color: colors.mutedForeground,
                ).copyWith(height: 1.55),
                children: [
                  TextSpan(text: instructionsPrefix),
                  TextSpan(
                    text: email,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.foreground,
                    ),
                  ),
                  TextSpan(text: instructionsSuffix),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
