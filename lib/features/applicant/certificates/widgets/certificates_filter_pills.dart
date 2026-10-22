import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../components/ui/app_button.dart';
import '../../../../components/ui/app_filter_pill.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../certificates_constants.dart';
import '../certificates_providers.dart';

/// Radio value for "no filter".
const String _all = '';

/// "Suggested: All" and "Validity: All" pills under the search field; both
/// open the same filter sheet, like the My applications list.
class CertificatesFilterPills extends StatelessWidget {
  const CertificatesFilterPills({
    super.key,
    required this.query,
    required this.onChanged,
  });

  final CertificatesQuery query;
  final ValueChanged<CertificatesQuery> onChanged;

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<CertificatesQuery>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CertificatesFilterSheet(initial: query),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    String pill(String label, String value) => tr(
      'certificates.filter.pill',
      namedArgs: {'label': label, 'value': value},
    );
    final suggested = query.suggested;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AppFilterPill(
          key: const Key('certificates_filter_suggested'),
          label: pill(
            tr('certificates.filter.suggestedLabel'),
            suggested == null
                ? tr('certificates.filter.all')
                : tr('certificates.filter.${suggested ? 'yes' : 'no'}'),
          ),
          active: suggested != null,
          onTap: () => _open(context),
        ),
        AppFilterPill(
          key: const Key('certificates_filter_validity'),
          label: pill(
            tr('certificates.filter.validity'),
            query.validity == null
                ? tr('certificates.filter.all')
                : tr(CertificateConstants.validityKey(query.validity!)),
          ),
          active: query.validity != null,
          onTap: () => _open(context),
        ),
      ],
    );
  }
}

/// "Filter certificates" sheet: suggested and validity in one place. Pops
/// with the new query when applied.
class CertificatesFilterSheet extends StatefulWidget {
  const CertificatesFilterSheet({super.key, required this.initial});

  final CertificatesQuery initial;

  @override
  State<CertificatesFilterSheet> createState() =>
      _CertificatesFilterSheetState();
}

class _CertificatesFilterSheetState extends State<CertificatesFilterSheet> {
  late String _suggested = widget.initial.suggested?.toString() ?? _all;
  late String _validity = widget.initial.validity ?? _all;

  CertificatesQuery _result() => widget.initial.copyWith(
    suggested: _suggested == _all ? null : _suggested == 'true',
    clearSuggested: _suggested == _all,
    validity: _validity == _all ? null : _validity,
    clearValidity: _validity == _all,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Widget caption(String key) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        tr(key).toUpperCase(),
        style: AppTypography.body(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: colors.mutedForeground,
        ),
      ),
    );

    Widget radios(
      String value,
      Map<String, String> options,
      ValueChanged<String> onChanged,
    ) => RadioGroup<String>(
      groupValue: value,
      onChanged: (v) => setState(() => onChanged(v!)),
      child: Column(
        children: [
          for (final e in options.entries) ...[
            RadioListTile<String>(
              value: e.key,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              activeColor: colors.primary,
              title: Text(
                e.value,
                style: AppTypography.body(
                  fontSize: 15,
                  color: colors.foreground,
                ),
              ),
            ),
            Divider(height: 1, color: colors.border),
          ],
        ],
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('certificates.filter.sheetTitle'),
              style: AppTypography.display(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
            caption('certificates.filter.suggested'),
            radios(_suggested, {
              _all: tr('certificates.filter.all'),
              'true': tr('certificates.filter.suggestedYes'),
              'false': tr('certificates.filter.suggestedNo'),
            }, (v) => _suggested = v),
            caption('certificates.filter.validity'),
            radios(_validity, {
              _all: tr('certificates.filter.all'),
              for (final v in CertificateConstants.validities)
                v: tr(CertificateConstants.validityKey(v)),
            }, (v) => _validity = v),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: tr('certificates.filter.reset'),
                    variant: AppButtonVariant.outline,
                    onPressed: () => setState(() {
                      _suggested = _all;
                      _validity = _all;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    text: tr('certificates.filter.apply'),
                    onPressed: () => Navigator.of(context).pop(_result()),
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
