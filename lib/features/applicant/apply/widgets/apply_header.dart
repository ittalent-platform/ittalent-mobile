import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../apply_constants.dart';

/// The top of the apply screens: the close (or back) button, "Apply", and
/// under it "Step n of 2" with a line that fills as the steps go. A page
/// without a step (a stop such as "This job just closed") has no line.
class ApplyHeader extends StatelessWidget {
  const ApplyHeader({
    super.key,
    required this.leading,
    required this.tooltip,
    required this.onLeading,
    this.step,
  });

  /// The X that closes the flow, or the chevron that goes back a step.
  final IconData leading;
  final String tooltip;
  final VoidCallback? onLeading;
  final int? step;

  static const double height = 52;
  static const double lineHeight = 3;
  static const double iconSize = 22;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final step = this.step;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: colors.card,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: height,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: IconButton(
                        tooltip: tooltip,
                        onPressed: onLeading,
                        icon: Icon(
                          leading,
                          size: iconSize,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tr('apply.title'),
                        style: AppTypography.body(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.foreground,
                        ),
                      ),
                      if (step != null)
                        Text(
                          tr(
                            'apply.step',
                            namedArgs: {
                              'step': '$step',
                              'total': '${ApplyConstants.totalSteps}',
                            },
                          ),
                          style: AppTypography.body(
                            fontSize: 12.5,
                            color: colors.mutedForeground,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: step == null ? 1 : lineHeight,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: colors.border)),
              if (step != null)
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: step / ApplyConstants.totalSteps,
                    child: ColoredBox(color: colors.primary),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
