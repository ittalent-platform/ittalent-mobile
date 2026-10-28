import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../theme/app_colors.dart';
import '../notifications_constants.dart';

class NotificationTypeIcon extends StatelessWidget {
  const NotificationTypeIcon({super.key, required this.type, this.size = 40.0});

  final String type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Color backgroundColor;
    Color iconColor;
    IconData iconData;

    switch (type) {
      case NotificationConstants.typeSystemAnnouncement:
        backgroundColor = const Color(0xFFFFF4ED);
        iconColor = colors.primary;
        iconData = LucideIcons.megaphone;
        break;

      case NotificationConstants.typeInterviewScheduled:
      case NotificationConstants.typeInterviewRescheduled:
        backgroundColor = const Color(0xFFEBF4FF);
        iconColor = const Color(0xFF1D4ED8);
        iconData = LucideIcons.calendar;
        break;

      case NotificationConstants.typeInterviewCancelled:
        backgroundColor = const Color(0xFFFEF2F2);
        iconColor = const Color(0xFFDC2626);
        iconData = LucideIcons.calendarX;
        break;

      case NotificationConstants.typeApplicationStatusChanged:
        backgroundColor = const Color(0xFFEDFCF2);
        iconColor = const Color(0xFF15803D);
        iconData = LucideIcons.trendingUp;
        break;

      case NotificationConstants.typeApplicationSubmitted:
        backgroundColor = const Color(0xFFF4F3EF);
        iconColor = colors.mutedForeground;
        iconData = LucideIcons.fileText;
        break;

      case NotificationConstants.typeAccountAlert:
        backgroundColor = const Color(0xFFF4F3EF);
        iconColor = colors.mutedForeground;
        iconData = LucideIcons.shieldCheck;
        break;

      default:
        backgroundColor = const Color(0xFFF4F3EF);
        iconColor = colors.mutedForeground;
        iconData = LucideIcons.bell;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Icon(iconData, size: 18, color: iconColor)),
    );
  }
}
