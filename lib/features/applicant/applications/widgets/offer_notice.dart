import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_typography.dart';

/// Peach note shown while an application is Offered. The candidate has no
/// in-app reply yet: the company follows up by email (TBD-MYAPP-07).
class OfferNotice extends StatelessWidget {
  const OfferNotice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.statusPeachBg,
        borderRadius: AppRadius.inputRadius,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.clock, size: 14, color: colors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
