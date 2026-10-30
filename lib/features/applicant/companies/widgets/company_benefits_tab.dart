import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/common/app_empty_state.dart';
import '../../../../components/ui/app_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

/// The Benefits tab: the perks the company lists, one per line.
class CompanyBenefitsTab extends StatelessWidget {
  const CompanyBenefitsTab({super.key, required this.benefits});

  final List<String> benefits;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (benefits.isEmpty) {
      return AppEmptyState(
        icon: const Icon(LucideIcons.gift),
        title: tr('companies.benefits.empty.title'),
        description: tr('companies.benefits.empty.description'),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        child: Column(
          children: [
            for (var i = 0; i < benefits.length; i++)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        LucideIcons.check,
                        size: 18,
                        color: colors.statusSuccessFg,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        benefits[i],
                        style: AppTypography.body(
                          fontSize: 15,
                          height: 1.5,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
