import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import 'apply_style.dart';

/// One choice of a list of documents: a radio, a title, and a line under it
/// (a [badge] such as "Default CV" may come before the line). The chosen card
/// has the brand colour as its outline and a faint tint.
class ApplyOptionCard extends StatelessWidget {
  const ApplyOptionCard({
    super.key,
    required this.selected,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badge,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final Widget? badge;
  final VoidCallback? onTap;

  static const double radius = 14;
  static const double radioSize = 22;
  static const double chosenRing = 7;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = BorderRadius.circular(radius);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? colors.chosen : colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: shape,
          side: BorderSide(
            color: selected ? colors.primary : colors.border,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: radioSize,
                  height: radioSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.card,
                    border: Border.all(
                      color: selected ? colors.primary : colors.control,
                      width: selected ? chosenRing : 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                      ),
                      if (subtitle != null || badge != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (badge != null) ...[
                              badge!,
                              if (subtitle != null) const SizedBox(width: 6),
                            ],
                            if (subtitle != null)
                              Expanded(
                                child: Text(
                                  subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.body(
                                    fontSize: 13,
                                    color: colors.mutedForeground,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
