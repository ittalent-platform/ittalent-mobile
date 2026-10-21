import 'package:flutter/material.dart';

import '../../../../components/ui/app_card.dart';
import '../../../../components/ui/app_skeleton.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';

const _circle = BorderRadius.all(Radius.circular(999));

/// Two text bars: a title and a muted line under it.
class _Lines extends StatelessWidget {
  const _Lines({required this.title, required this.subtitle});

  final double title;
  final double subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppSkeleton(width: title, height: 16),
      const SizedBox(height: 8),
      AppSkeleton(width: subtitle, height: 12),
    ],
  );
}

/// The detail page's shape while it loads: header, status card, menu rows.
class ApplicationDetailSkeleton extends StatelessWidget {
  const ApplicationDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const Row(
          children: [
            AppSkeleton(
              width: 52,
              height: 52,
              borderRadius: AppRadius.inputRadius,
            ),
            SizedBox(width: 12),
            _Lines(title: 200, subtitle: 140),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: [
              const Row(
                children: [
                  AppSkeleton(width: 40, height: 40, borderRadius: _circle),
                  SizedBox(width: 12),
                  _Lines(title: 130, subtitle: 180),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (var i = 0; i < 5; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    const Expanded(
                      child: AppSkeleton(height: 6, borderRadius: _circle),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.border),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _Lines(title: 140, subtitle: 200),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The status history timeline while it loads.
class ApplicationHistorySkeleton extends StatelessWidget {
  const ApplicationHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(vertical: 16),
    children: [
      AppCard(
        child: Column(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(height: 20),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: AppSkeleton(
                      width: 10,
                      height: 10,
                      borderRadius: _circle,
                    ),
                  ),
                  SizedBox(width: 12),
                  _Lines(title: 160, subtitle: 210),
                ],
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
