import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

class AuthFooterNote extends StatelessWidget {
  const AuthFooterNote({super.key, this.onTapEmployerLink});

  final VoidCallback? onTapEmployerLink;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: GestureDetector(
        onTap: onTapEmployerLink,
        child: Text.rich(
          TextSpan(
            text: 'Hiring? Use ',
            style: AppTypography.body(
              fontSize: 12,
              color: colors.mutedForeground,
            ),
            children: [
              TextSpan(
                text: 'ITTalent for employers',
                style: AppTypography.body(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.fgLink,
                ),
              ),
              const TextSpan(text: ' on the web.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
