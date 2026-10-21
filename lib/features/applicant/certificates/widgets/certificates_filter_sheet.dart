import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../components/ui/app_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../certificates_constants.dart';
import '../certificates_providers.dart';

/// Edits the selection-state and validity filters; pops the new query when applied.
class CertificatesFilterSheet extends StatefulWidget {
  const CertificatesFilterSheet({super.key, required this.initial});

  final CertificatesQuery initial;

  @override
  State<CertificatesFilterSheet> createState() =>
      _CertificatesFilterSheetState();
}

class _CertificatesFilterSheetState extends State<CertificatesFilterSheet> {
  late CertificatesQuery _query = widget.initial;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget heading(String key) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        tr(key),
        style: AppTypography.body(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colors.mutedForeground,
        ),
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('certificates.filter.title'),
              style: AppTypography.display(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
            heading('certificates.filter.suggested'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in const [true, false])
                  ChoiceChip(
                    label: Text(
                      tr(
                        value
                            ? 'certificates.filter.suggestedYes'
                            : 'certificates.filter.suggestedNo',
                      ),
                    ),
                    selected: _query.suggested == value,
                    onSelected: (on) => setState(() {
                      _query = on
                          ? _query.copyWith(suggested: value)
                          : _query.copyWith(clearSuggested: true);
                    }),
                  ),
              ],
            ),
            heading('certificates.filter.validity'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in CertificateConstants.validities)
                  ChoiceChip(
                    label: Text(tr(CertificateConstants.validityKey(value))),
                    selected: _query.validity == value,
                    onSelected: (on) => setState(() {
                      _query = on
                          ? _query.copyWith(validity: value)
                          : _query.copyWith(clearValidity: true);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: tr('certificates.filter.clear'),
                    variant: AppButtonVariant.outline,
                    onPressed: () => setState(() {
                      _query = CertificatesQuery(search: _query.search);
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: tr('certificates.filter.apply'),
                    onPressed: () => Navigator.of(context).pop(_query),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
