import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import 'apply_option_card.dart';

/// "Upload a new CV": a card with a dashed outline. While a file is being
/// uploaded it shows a spinner and cannot be tapped again.
class ApplyUploadCard extends StatelessWidget {
  const ApplyUploadCard({
    super.key,
    required this.title,
    required this.hint,
    required this.onTap,
    this.uploading = false,
  });

  final String title;
  final String hint;
  final VoidCallback? onTap;
  final bool uploading;

  static const double iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      enabled: onTap != null && !uploading,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ApplyOptionCard.radius),
          onTap: uploading ? null : onTap,
          child: CustomPaint(
            painter: _DashedOutlinePainter(
              color: colors.input,
              radius: ApplyOptionCard.radius,
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  SizedBox(
                    width: ApplyOptionCard.radioSize,
                    child: Center(
                      child: uploading
                          ? SizedBox(
                              width: iconSize,
                              height: iconSize,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.fgLink,
                              ),
                            )
                          : Icon(
                              LucideIcons.upload,
                              size: iconSize,
                              color: colors.fgLink,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            fontSize: 13,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedOutlinePainter extends CustomPainter {
  const _DashedOutlinePainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double dash = 4;
  static const double gap = 3;
  static const double width = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(width / 2),
          Radius.circular(radius - width / 2),
        ),
      );
    for (final metric in outline.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += dash + gap) {
        canvas.drawPath(
          metric.extractPath(at, math.min(at + dash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutlinePainter old) =>
      old.color != color || old.radius != radius;
}
