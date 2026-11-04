import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

/// The text of a job as the recruiter wrote it: paragraphs, and lines that
/// start with "-", "*" or "•" as a bulleted list.
class JobTextBlock extends StatelessWidget {
  const JobTextBlock({super.key, required this.text});

  final String text;

  static const double bulletIndent = 20;
  static final RegExp _bullet = RegExp(r'^[-*•]\s+');

  /// The non-empty lines of [text], with their bullet marker removed.
  static List<({bool bullet, String text})> lines(String text) => [
    for (final raw in text.split('\n'))
      if (raw.trim().isNotEmpty)
        (
          bullet: _bullet.hasMatch(raw.trim()),
          text: raw.trim().replaceFirst(_bullet, ''),
        ),
  ];

  /// [text] on one line, to be shortened with an ellipsis.
  static String flat(String text) => lines(text).map((e) => e.text).join(' ');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = lines(text);
    final style = AppTypography.body(
      fontSize: 15,
      height: 1.55,
      color: colors.foreground,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(height: items[i].bullet ? 6 : 8),
          if (items[i].bullet)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: bulletIndent,
                  child: Text('•', style: style),
                ),
                Expanded(child: Text(items[i].text, style: style)),
              ],
            )
          else
            Text(items[i].text, style: style),
        ],
      ],
    );
  }
}
