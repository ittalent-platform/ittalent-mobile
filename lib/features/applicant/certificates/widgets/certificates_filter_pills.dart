import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../components/ui/app_filter_pill.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../certificates_constants.dart';
import '../certificates_providers.dart';

/// Radio value for "no filter".
const String _all = '';

enum CertificateFilter { suggested, validity }

/// "Suggested: All" and "Validity: All" pills under the search field. Each
/// opens a sheet with only its own options; picking one applies it.
class CertificatesFilterPills extends StatelessWidget {
  const CertificatesFilterPills({
    super.key,
    required this.query,
    required this.onChanged,
  });

  final CertificatesQuery query;
  final ValueChanged<CertificatesQuery> onChanged;

  Future<void> _open(BuildContext context, CertificateFilter filter) async {
    final result = await showModalBottomSheet<CertificatesQuery>(
      context: context,
      showDragHandle: true,
      builder: (_) => CertificatesFilterSheet(filter: filter, initial: query),
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
          onTap: () => _open(context, CertificateFilter.suggested),
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
          onTap: () => _open(context, CertificateFilter.validity),
        ),
      ],
    );
  }
}

/// One filter's options as a radio list. Picking an option pops with the new
/// query; "All" clears that filter.
class CertificatesFilterSheet extends StatelessWidget {
  const CertificatesFilterSheet({
    super.key,
    required this.filter,
    required this.initial,
  });

  final CertificateFilter filter;
  final CertificatesQuery initial;

  CertificatesQuery _result(String value) => switch (filter) {
    CertificateFilter.suggested =>
      value == _all
          ? initial.copyWith(clearSuggested: true)
          : initial.copyWith(suggested: value == 'true'),
    CertificateFilter.validity =>
      value == _all
          ? initial.copyWith(clearValidity: true)
          : initial.copyWith(validity: value),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (title, value, options) = switch (filter) {
      CertificateFilter.suggested => (
        'certificates.filter.suggested',
        initial.suggested?.toString() ?? _all,
        {
          _all: tr('certificates.filter.all'),
          'true': tr('certificates.filter.suggestedYes'),
          'false': tr('certificates.filter.suggestedNo'),
        },
      ),
      CertificateFilter.validity => (
        'certificates.filter.validity',
        initial.validity ?? _all,
        {
          _all: tr('certificates.filter.all'),
          for (final v in CertificateConstants.validities)
            v: tr(CertificateConstants.validityKey(v)),
        },
      ),
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(title),
              style: AppTypography.display(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: value,
              onChanged: (v) => Navigator.of(context).pop(_result(v!)),
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
            ),
          ],
        ),
      ),
    );
  }
}
