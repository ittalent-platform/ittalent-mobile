import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../components/ui/app_badge.dart';
import '../../../../components/ui/app_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../applications_constants.dart';
import '../applications_providers.dart';
import 'company_avatar.dart';
import 'offer_notice.dart';

class ApplicationCard extends StatelessWidget {
  const ApplicationCard({super.key, required this.item, this.onTap});

  final ApplicationItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    String date(DateTime d) => ApplicationConstants.shortDate(d, locale);
    final closed =
        item.status == ApplicationConstants.statusWithdrawn ||
        item.status == ApplicationConstants.statusRejected;
    final metaStyle = AppTypography.body(
      fontSize: 12,
      color: colors.mutedForeground,
    );

    final String meta;
    if (item.status == ApplicationConstants.statusWithdrawn &&
        item.withdrawnAt != null) {
      final withdrawn = tr(
        'applications.card.withdrawn',
        namedArgs: {'date': date(item.withdrawnAt!)},
      );
      meta = item.canApplyAgain
          ? '$withdrawn · ${tr('applications.card.applyAgain')}'
          : withdrawn;
    } else {
      meta = [
        if (item.submittedAt != null)
          tr(
            'applications.card.submitted',
            namedArgs: {'date': date(item.submittedAt!)},
          ),
        if (item.latestStatusAt != null)
          tr(
            'applications.card.updated',
            namedArgs: {'date': date(item.latestStatusAt!)},
          ),
      ].join(' · ');
    }

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanyAvatar(name: item.companyName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.jobTitle,
                      style: AppTypography.display(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: closed
                            ? colors.mutedForeground
                            : colors.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        item.companyName,
                        if (item.location != null) item.location!,
                      ].join(' · '),
                      style: AppTypography.body(
                        fontSize: 13,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // The title takes the free width so the badge sits at the
              // right edge, as in the design; a long label ellipsizes.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: AppBadge(
                  label: tr(ApplicationConstants.statusKey(item.status)),
                  tone: ApplicationConstants.badgeToneForStatus(item.status),
                ),
              ),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(meta, style: metaStyle),
          ],
          if (item.status == ApplicationConstants.statusOffered) ...[
            const SizedBox(height: 10),
            OfferNotice(
              text: tr(
                'applications.card.offer',
                namedArgs: {'company': item.companyName},
              ),
            ),
          ],
        ],
      ),
    );
  }
}
