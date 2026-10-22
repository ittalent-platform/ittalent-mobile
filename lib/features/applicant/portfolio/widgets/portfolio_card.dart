import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/ui/app_badge.dart';
import '../../../../components/ui/app_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_typography.dart';
import '../portfolio_providers.dart';

/// One portfolio link, in the same card pattern as certificates.
class PortfolioCard extends StatelessWidget {
  const PortfolioCard({
    super.key,
    required this.link,
    required this.onOpenLink,
    required this.onMore,
    this.highlighted = false,
  });

  final PortfolioLink link;
  final VoidCallback onOpenLink;
  final VoidCallback onMore;

  /// Just added: outlined in the brand colour.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      borderColor: highlighted ? colors.primary : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.muted,
              borderRadius: AppRadius.buttonRadius,
            ),
            alignment: Alignment.center,
            child: Icon(LucideIcons.link, size: 20, color: colors.foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.title,
                  style: AppTypography.display(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.foreground,
                  ),
                ),
                if (link.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    link.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      fontSize: 13,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                InkWell(
                  onTap: onOpenLink,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          link.domain,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.fgLink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.externalLink,
                        size: 13,
                        color: colors.fgLink,
                      ),
                    ],
                  ),
                ),
                if (!link.isHttps) ...[
                  const SizedBox(height: 8),
                  AppBadge(
                    label: tr('portfolio.notHttps'),
                    tone: BadgeTone.warning,
                    icon: const Icon(LucideIcons.triangleAlert),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: tr('portfolio.moreFor', namedArgs: {'name': link.title}),
            visualDensity: VisualDensity.compact,
            icon: Icon(
              LucideIcons.ellipsisVertical,
              size: 18,
              color: colors.mutedForeground,
            ),
            onPressed: onMore,
          ),
        ],
      ),
    );
  }
}
