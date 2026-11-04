import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_typography.dart';
import '../apply_constants.dart';
import '../apply_models.dart';

/// Step 2: the optional note to the company, with how much of the 1,000
/// characters it uses.
class ApplyMessageField extends StatelessWidget {
  const ApplyMessageField({
    super.key,
    required this.controller,
    required this.company,
    required this.enabled,
  });

  final TextEditingController controller;
  final String company;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final separator = tr('apply.thousandsSeparator');
    final input = AppTypography.body(
      fontSize: 16,
      height: 1.5,
      color: colors.foreground,
    );
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: AppRadius.inputRadius,
      borderSide: BorderSide(color: color, width: width),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('apply.messageLabel', namedArgs: {'company': company}),
          style: AppTypography.body(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          minLines: ApplyConstants.messageMinLines,
          maxLines: ApplyConstants.messageMaxLines,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [
            LengthLimitingTextInputFormatter(ApplyConstants.messageMaxLength),
          ],
          style: input,
          decoration: InputDecoration(
            hintText: tr('apply.messageHint'),
            hintStyle: input.copyWith(color: colors.mutedForeground),
            filled: true,
            fillColor: colors.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: border(colors.input, 1),
            enabledBorder: border(colors.input, 1),
            disabledBorder: border(colors.input, 1),
            focusedBorder: border(colors.primary, 1.5),
          ),
        ),
        const SizedBox(height: 6),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => Text(
            tr(
              'apply.messageCount',
              namedArgs: {
                'count': formatCount(value.text.length, separator),
                'max': formatCount(ApplyConstants.messageMaxLength, separator),
              },
            ),
            style: AppTypography.body(
              fontSize: 13.5,
              height: 1.4,
              color: colors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}
