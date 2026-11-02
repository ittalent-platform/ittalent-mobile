import 'package:flutter/material.dart';

import '../../../../components/ui/app_card.dart';
import '../../../../components/ui/app_skeleton.dart';

/// Placeholder with the shape of the job page, so it keeps its layout while
/// loading.
class JobDetailSkeleton extends StatelessWidget {
  const JobDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 56, height: 56),
          SizedBox(height: 14),
          AppSkeleton(height: 24),
          SizedBox(height: 10),
          AppSkeleton(width: 220, height: 14),
          SizedBox(height: 14),
          Row(
            children: [
              AppSkeleton(width: 110, height: 32),
              SizedBox(width: 8),
              AppSkeleton(width: 90, height: 32),
            ],
          ),
          SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: 60, height: 12),
                SizedBox(height: 10),
                AppSkeleton(width: 150, height: 24),
              ],
            ),
          ),
          SizedBox(height: 20),
          AppSkeleton(width: 140, height: 18),
          SizedBox(height: 12),
          AppSkeleton(height: 14),
          SizedBox(height: 8),
          AppSkeleton(height: 14),
          SizedBox(height: 8),
          AppSkeleton(width: 200, height: 14),
        ],
      ),
    );
  }
}
