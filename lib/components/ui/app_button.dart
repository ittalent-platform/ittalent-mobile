import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, destructive }
enum AppButtonSize { sm, md, lg, icon }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    this.text,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : assert(
         text != null || icon != null,
         'AppButton requires either text or icon',
       );

  final VoidCallback? onPressed;
  final String? text;
  final Widget? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEnabled = onPressed != null && !isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = colors.primary;
        foregroundColor = colors.primaryForeground;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = colors.secondary;
        foregroundColor = colors.secondaryForeground;
        break;
      case AppButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = colors.foreground;
        borderSide = BorderSide(color: colors.border, width: 1);
        break;
      case AppButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = colors.foreground;
        break;
      case AppButtonVariant.destructive:
        backgroundColor = colors.destructive;
        foregroundColor = colors.destructiveForeground;
        break;
    }

    if (!isEnabled) {
      backgroundColor = backgroundColor.withValues(alpha: 0.5);
      foregroundColor = foregroundColor.withValues(alpha: 0.5);
    }

    EdgeInsets padding;
    double fontSize;
    double height;

    switch (size) {
      case AppButtonSize.sm:
        height = 36;
        padding = const EdgeInsets.symmetric(horizontal: 12);
        fontSize = 13;
        break;
      case AppButtonSize.md:
        height = 44;
        padding = const EdgeInsets.symmetric(horizontal: 16);
        fontSize = 14;
        break;
      case AppButtonSize.lg:
        height = 50;
        padding = const EdgeInsets.symmetric(horizontal: 20);
        fontSize = 16;
        break;
      case AppButtonSize.icon:
        height = 40;
        padding = EdgeInsets.zero;
        fontSize = 14;
        break;
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    } else {
      content = Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(color: foregroundColor, size: 18),
              child: icon!,
            ),
            if (text != null) const SizedBox(width: 8),
          ],
          if (text != null)
            Text(
              text!,
              style: AppTypography.body(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: foregroundColor,
              ),
            ),
        ],
      );
    }

    Widget button = Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.buttonRadius,
        side: borderSide,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        child: Container(
          height: height,
          width: size == AppButtonSize.icon ? height : (isFullWidth ? double.infinity : null),
          padding: size == AppButtonSize.icon ? EdgeInsets.zero : padding,
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    return button;
  }
}
