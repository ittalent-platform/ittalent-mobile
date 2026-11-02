import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/ui/app_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../apply_models.dart';
import 'apply_pill.dart';
import 'apply_style.dart';

/// Step 2: the certificate links the applicant can send. The ones they
/// marked "suggest when I apply" start ticked. A link that has expired, or
/// is not HTTPS, can still be sent; it is marked so, as companies see it.
class ApplyCertificatesCard extends StatelessWidget {
  const ApplyCertificatesCard({
    super.key,
    required this.certificates,
    required this.ticked,
    required this.onToggle,
    required this.now,
  });

  final List<ApplyCertificate> certificates;
  final Set<String> ticked;
  final ValueChanged<ApplyCertificate> onToggle;
  final DateTime now;

  static const double boxSize = 22;

  String _line(BuildContext context, ApplyCertificate item) {
    final expiry = item.expiryDate == null
        ? tr('certificates.noExpiry')
        : tr(
            item.isExpired(now)
                ? 'certificates.expiredOn'
                : 'certificates.expiresOn',
            namedArgs: {'date': _displayDate(context, item.expiryDate!)},
          );
    return '${item.domain} · $expiry';
  }

  static String _displayDate(BuildContext context, String day) {
    final date = DateTime.tryParse(day);
    if (date == null) return day;
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('d MMM yyyy', locale).format(date);
  }

  Widget _box(BuildContext context, bool checked) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: checked ? colors.primary : colors.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: checked ? colors.primary : colors.control,
          width: 1,
        ),
      ),
      child: checked
          ? Icon(LucideIcons.check, size: 14, color: colors.primaryForeground)
          : null,
    );
  }

  Widget _row(
    BuildContext context,
    ApplyCertificate item, {
    required bool first,
  }) {
    final colors = context.colors;
    final checked = ticked.contains(item.id);
    final expired = item.isExpired(now);
    return Semantics(
      container: true,
      checked: checked,
      child: InkWell(
        onTap: () => onToggle(item),
        child: Container(
          padding: EdgeInsets.fromLTRB(0, first ? 0 : 12, 0, 12),
          decoration: BoxDecoration(
            border: first
                ? null
                : Border(top: BorderSide(color: colors.border, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(context, checked),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTypography.body(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _line(context, item),
                          style: AppTypography.body(
                            fontSize: 13,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (expired || !item.isHttps) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (expired)
                      ApplyPill(
                        label: tr('certificates.expired'),
                        tone: ApplyPillTone.neutral,
                      ),
                    if (!item.isHttps)
                      ApplyPill(
                        label: tr('certificates.notHttps'),
                        tone: ApplyPillTone.warning,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('apply.certificates').toUpperCase(),
            style: AppTypography.body(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.78,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr('apply.certificatesHint'),
            style: AppTypography.body(
              fontSize: 13.5,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < certificates.length; i++)
            _row(context, certificates[i], first: i == 0),
        ],
      ),
    );
  }
}
