import 'package:flutter/material.dart';

/// Renders a translation that marks emphasis with `<b>…</b>` (shared with web).
class BoldMarkupText extends StatelessWidget {
  const BoldMarkupText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    // Odd segments sit between <b> and </b>.
    final parts = text.split(RegExp('</?b>'));
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (final (i, part) in parts.indexed)
            TextSpan(
              text: part,
              style: i.isOdd
                  ? const TextStyle(fontWeight: FontWeight.w700)
                  : null,
            ),
        ],
      ),
    );
  }
}
