import 'package:flutter/material.dart';

/// The official ITTalent platform vector monogram icon.
///
/// Faithfully reproduces the 40x40 SVG geometry:
/// - Rounded squircle container with radius 11
/// - Circular head (cx: 20, cy: 10.4, r: 4.4)
/// - Upward-curved arms path (M9 24 Q20 13.2 31 24, stroke width 5.4, round cap)
/// - Central body trunk (rect at 17.3, 19, size 5.4x15, radius 2.7)
class ITTalentMonogram extends StatelessWidget {
  const ITTalentMonogram({
    super.key,
    this.size = 26,
    this.backgroundColor = const Color(0xFFF2470C),
    this.glyphColor = Colors.white,
  });

  final double size;
  final Color backgroundColor;
  final Color glyphColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _ITTalentMonogramPainter(
          backgroundColor: backgroundColor,
          glyphColor: glyphColor,
        ),
      ),
    );
  }
}

class _ITTalentMonogramPainter extends CustomPainter {
  const _ITTalentMonogramPainter({
    required this.backgroundColor,
    required this.glyphColor,
  });

  final Color backgroundColor;
  final Color glyphColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 40.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Background rounded rectangle (40x40, rx: 11)
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 40, 40),
        const Radius.circular(11),
      ),
      bgPaint,
    );

    final glyphFill = Paint()
      ..color = glyphColor
      ..style = PaintingStyle.fill;

    // 2. Head circle (cx: 20, cy: 10.4, r: 4.4)
    canvas.drawCircle(const Offset(20, 10.4), 4.4, glyphFill);

    // 3. Upward curved arms (M9 24 Q20 13.2 31 24, stroke-width 5.4, round caps)
    final armPaint = Paint()
      ..color = glyphColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.4
      ..strokeCap = StrokeCap.round;

    final armPath = Path()
      ..moveTo(9, 24)
      ..quadraticBezierTo(20, 13.2, 31, 24);
    canvas.drawPath(armPath, armPaint);

    // 4. Central body trunk (x: 17.3, y: 19, w: 5.4, h: 15, rx: 2.7)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(17.3, 19, 5.4, 15),
        const Radius.circular(2.7),
      ),
      glyphFill,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ITTalentMonogramPainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.glyphColor != glyphColor;
}
