import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Rounded square with the company's initials; the colour is derived from the
/// name so the same company always looks the same. [tinted] swaps the solid
/// tile for a light tint with coloured initials, as on the job and company
/// cards.
class CompanyAvatar extends StatelessWidget {
  const CompanyAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.tinted = false,
  });

  final String name;
  final double size;
  final bool tinted;

  static const double tintAlpha = 0.12;

  /// "CloudBridge" → CB, "Pixel Labs" → PL, "Acme" → AC.
  static String initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return '?';
    if (words.length > 1) return (words[0][0] + words[1][0]).toUpperCase();
    final capitals = words[0].replaceAll(RegExp(r'[^A-Z]'), '');
    if (capitals.length > 1) return capitals.substring(0, 2);
    return words[0].substring(0, words[0].length > 1 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = [
      colors.statusSuccessFg,
      colors.statusInfoFg,
      colors.statusWarningFg,
      colors.primary,
      colors.statusErrorFg,
      colors.statusBlockedFg,
    ];
    final hash = name.codeUnits.fold<int>(0, (sum, c) => sum + c);
    final tone = palette[hash % palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tinted ? tone.withValues(alpha: tintAlpha) : tone,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Text(
        initials(name),
        style: AppTypography.body(
          fontSize: size * 0.33,
          fontWeight: FontWeight.w700,
          color: tinted ? tone : colors.card,
        ),
      ),
    );
  }
}
