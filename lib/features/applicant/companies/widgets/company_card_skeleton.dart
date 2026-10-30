import 'package:flutter/material.dart';

import '../../../../components/ui/app_card.dart';
import '../../../../components/ui/app_skeleton.dart';
import '../companies_constants.dart';

/// Stands in for a [CompanyCard] while the list loads.
class CompanyCardSkeleton extends StatelessWidget {
  const CompanyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppSkeleton(
                width: CompanyConstants.cardLogoSize,
                height: CompanyConstants.cardLogoSize,
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton(width: 160, height: 14),
                  SizedBox(height: 8),
                  AppSkeleton(width: 110, height: 12),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          AppSkeleton(height: 12),
          SizedBox(height: 8),
          AppSkeleton(width: 200, height: 12),
        ],
      ),
    );
  }
}
