import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/ui/app_badge.dart';
import '../../../../components/ui/app_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_typography.dart';
import '../certificates_constants.dart';
import '../certificates_providers.dart';

/// One certificate: what companies see, the link, and the "Suggest when I apply" switch.
class CertificateCard extends StatelessWidget {
  const CertificateCard({
    super.key,
    required this.item,
    required this.onOpenLink,
    required this.onMore,
    required this.onSuggestedChanged,
  });

  final CertificateLink item;
  final VoidCallback onOpenLink;
  final VoidCallback onMore;
  final ValueChanged<bool>? onSuggestedChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final expired = item.isExpired(DateTime.now());
    final issued = tr(
      'certificates.issuedOn',
      namedArgs: {
        'date': item.issuedDate == null
            ? '—'
            : CertificateConstants.displayDate(item.issuedDate!),
      },
    );
    final expiry = item.expiryDate == null
        ? tr('certificates.noExpiry')
        : tr(
            expired ? 'certificates.expiredOn' : 'certificates.expiresOn',
            namedArgs: {
              'date': CertificateConstants.displayDate(item.expiryDate!),
            },
          );
    final muted = AppTypography.body(
      fontSize: 13,
      color: colors.mutedForeground,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: Icon(
                  LucideIcons.award,
                  size: 20,
                  color: colors.foreground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTypography.display(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.issuer ?? tr('certificates.noIssuer'),
                      style: muted,
                    ),
                    const SizedBox(height: 2),
                    Text('$issued · $expiry', style: muted),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: onOpenLink,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              item.domain,
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
                    if (expired || !item.isHttps) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (expired)
                            AppBadge(label: tr('certificates.expired')),
                          if (!item.isHttps)
                            AppBadge(
                              label: tr('certificates.notHttps'),
                              tone: BadgeTone.warning,
                              icon: const Icon(LucideIcons.triangleAlert),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: tr(
                  'certificates.moreFor',
                  namedArgs: {'name': item.name},
                ),
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
          Padding(
            padding: const EdgeInsets.only(left: 52, top: 8),
            child: Column(
              children: [
                Divider(height: 1, color: colors.border),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr('certificates.suggestWhenApply'),
                        style: AppTypography.body(
                          fontSize: 14,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                    Semantics(
                      label: tr(
                        'certificates.suggestFor',
                        namedArgs: {'name': item.name},
                      ),
                      child: Switch(
                        value: item.suggested,
                        onChanged: onSuggestedChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
