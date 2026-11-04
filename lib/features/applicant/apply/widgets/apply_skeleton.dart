import 'package:flutter/material.dart';

import '../../../../components/ui/app_skeleton.dart';
import 'apply_option_card.dart';

/// Placeholder with the shape of step 1, so the page keeps its layout while
/// the job and the documents load.
class ApplySkeleton extends StatelessWidget {
  const ApplySkeleton({super.key});

  Widget _card() => AppSkeleton(
    height: 68,
    borderRadius: BorderRadius.circular(ApplyOptionCard.radius),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppSkeleton(
                width: 44,
                height: 44,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(height: 18),
                    SizedBox(height: 8),
                    AppSkeleton(width: 160, height: 13),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const AppSkeleton(width: 60, height: 20),
          const SizedBox(height: 12),
          _card(),
          const SizedBox(height: 10),
          _card(),
          const SizedBox(height: 10),
          _card(),
        ],
      ),
    );
  }
}
