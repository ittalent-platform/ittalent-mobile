import 'package:flutter/material.dart';

import '../../../../components/ui/app_badge.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

/// A page that says one thing: a round icon, a title, a few lines, and the
/// way out. It shows what stops an application ("This job just closed") and
/// what ends it ("Application submitted").
class ApplyStatusView extends StatelessWidget {
  const ApplyStatusView({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  final IconData icon;
  final BadgeTone tone;
  final String title;
  final InlineSpan body;
  final List<Widget> actions;

  static const double discSize = 76;
  static const double iconSize = 34;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = switch (tone) {
      BadgeTone.success => (colors.statusSuccessBg, colors.statusSuccessFg),
      BadgeTone.warning => (colors.statusWarningBg, colors.statusWarningFg),
      BadgeTone.error => (colors.statusErrorBg, colors.statusErrorFg),
      BadgeTone.info => (colors.statusInfoBg, colors.statusInfoFg),
      _ => (colors.muted, colors.mutedForeground),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: discSize,
            height: discSize,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: iconSize, color: foreground),
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.display(
              fontSize: 28,
              height: 1.15,
              color: colors.foreground,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          body,
          textAlign: TextAlign.center,
          style: AppTypography.body(
            fontSize: 15.5,
            height: 1.55,
            color: colors.mutedForeground,
          ),
        ),
        for (final action in actions) ...[const SizedBox(height: 12), action],
      ],
    );
  }
}
