import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    this.controller,
    this.label,
    this.labelTrailing,
    this.hintText,
    this.helperText,
    this.errorText,
    this.isRequired = false,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final String? label;
  final Widget? labelTrailing;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool isRequired;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || labelTrailing != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          label!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                        ),
                      ),
                      if (isRequired)
                        Text(
                          ' *',
                          style: AppTypography.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.destructive,
                          ),
                        ),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),
              ?labelTrailing,
            ],
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          style: AppTypography.body(fontSize: 14, color: colors.foreground),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.body(
              fontSize: 14,
              color: colors.mutedForeground,
            ),
            helperText: helperText,
            helperMaxLines: 2,
            helperStyle: AppTypography.body(
              fontSize: 13.5,
              color: colors.mutedForeground,
            ),
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: readOnly ? colors.muted : colors.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.inputRadius,
              borderSide: BorderSide(color: colors.input, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.inputRadius,
              borderSide: BorderSide(
                color: errorText != null ? colors.destructive : colors.input,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.inputRadius,
              borderSide: BorderSide(
                color: errorText != null ? colors.destructive : colors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
