import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

enum ExploreTab { jobs, companies }

/// The title of the Explore tab: "Jobs" and "Companies" side by side. The one
/// on show is large and underlined; the other one opens its list.
class ExploreHeader extends StatelessWidget {
  const ExploreHeader({super.key, required this.selected});

  final ExploreTab selected;

  static const double selectedSize = 28;
  static const double otherSize = 22;
  static const double underlineHeight = 3;
  static const double underlineGap = 8;
  static const double tabGap = 22;

  Widget _tab(BuildContext context, ExploreTab tab) {
    final colors = context.colors;
    final active = tab == selected;
    final label = tr(tab == ExploreTab.jobs ? 'nav.jobs' : 'nav.companies');
    final route = tab == ExploreTab.jobs ? AppRoutes.jobs : AppRoutes.companies;
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: active ? null : () => context.go(route),
        child: Container(
          padding: const EdgeInsets.only(top: 4, bottom: underlineGap),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? colors.primary : Colors.transparent,
                width: underlineHeight,
              ),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.display(
              fontSize: active ? selectedSize : otherSize,
              fontWeight: FontWeight.w600,
              color: active ? colors.foreground : colors.mutedForeground,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Both titles stay on one line: on a narrow screen, or with a large system
    // font, they shrink together rather than overflow.
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _tab(context, ExploreTab.jobs),
            const SizedBox(width: tabGap),
            _tab(context, ExploreTab.companies),
          ],
        ),
      ),
    );
  }
}
