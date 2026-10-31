import 'package:flutter/material.dart';

import '../../../../components/ui/app_card.dart';
import '../../../../components/ui/app_skeleton.dart';
import 'job_card.dart';

/// Placeholder with the shape of a [JobCard], so the list keeps its layout
/// while loading.
class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(
                width: JobCard.avatarSize,
                height: JobCard.avatarSize,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(height: 16),
                    SizedBox(height: 8),
                    AppSkeleton(width: 140, height: 12),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          AppSkeleton(width: 120, height: 14),
          SizedBox(height: 12),
          Row(
            children: [
              AppSkeleton(width: 64, height: 24),
              SizedBox(width: 6),
              AppSkeleton(width: 48, height: 24),
            ],
          ),
        ],
      ),
    );
  }
}
