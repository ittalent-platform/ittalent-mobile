import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../components/ui/app_badge.dart';
import '../../../../components/ui/app_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../certificates_providers.dart';

class CertificateCard extends StatelessWidget {
  const CertificateCard({super.key, required this.item, this.onTap});

  final CertificateLink item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final expired = item.isExpired(DateTime.now());
    final dates = [
      if (item.issuedDate != null)
        tr('certificates.issuedOn', namedArgs: {'date': item.issuedDate!}),
      if (item.expiryDate == null)
        tr('certificates.noExpiry')
      else
        tr(
          expired ? 'certificates.expiredOn' : 'certificates.expiresOn',
          namedArgs: {'date': item.expiryDate!},
        ),
    ].join(' · ');

    final card = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: AppTypography.display(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.issuer ?? tr('certificates.noIssuer'),
            style: AppTypography.body(
              fontSize: 14,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dates,
            style: AppTypography.body(
              fontSize: 12,
              color: colors.mutedForeground,
            ),
          ),
          if (expired || item.suggested) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (expired)
                  AppBadge(
                    label: tr('certificates.expired'),
                    tone: BadgeTone.error,
                  ),
                if (item.suggested)
                  AppBadge(
                    label: tr('certificates.suggestOnApply'),
                    tone: BadgeTone.info,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
    return onTap == null ? card : InkWell(onTap: onTap, child: card);
  }
}
