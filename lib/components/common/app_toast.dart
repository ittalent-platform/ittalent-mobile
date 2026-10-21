import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Shows the design's toast: a floating card with a status icon and a short
/// message. Takes the messenger so callers can grab it before an `await`.
void showAppToast(
  ScaffoldMessengerState messenger,
  String message, {
  bool error = false,
  SnackBarAction? action,
}) {
  final colors = AppColors.inverseOf(Theme.of(messenger.context).brightness);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        action: action,
        content: Row(
          children: [
            Icon(
              error ? LucideIcons.circleAlert : LucideIcons.circleCheck,
              size: 20,
              color: error ? colors.statusErrorFg : colors.statusSuccessFg,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTypography.body(
                  fontSize: 14,
                  color: colors.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
