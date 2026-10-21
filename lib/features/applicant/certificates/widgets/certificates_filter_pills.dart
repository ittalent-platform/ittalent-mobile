import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_typography.dart';
import '../certificates_constants.dart';
import '../certificates_providers.dart';

/// "Suggested: All" and "Validity: All" dropdown pills under the search field.
class CertificatesFilterPills extends StatelessWidget {
  const CertificatesFilterPills({
    super.key,
    required this.query,
    required this.onChanged,
  });

  final CertificatesQuery query;
  final ValueChanged<CertificatesQuery> onChanged;

  static const _all = 'all';

  @override
  Widget build(BuildContext context) {
    final suggestedOptions = {
      _all: tr('certificates.filter.all'),
      'true': tr('certificates.filter.yes'),
      'false': tr('certificates.filter.no'),
    };
    final validityOptions = {
      _all: tr('certificates.filter.all'),
      for (final v in CertificateConstants.validities)
        v: tr(CertificateConstants.validityKey(v)),
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Pill(
          key: const Key('certificates_filter_suggested'),
          label: tr('certificates.filter.suggestedLabel'),
          value: query.suggested?.toString() ?? _all,
          options: suggestedOptions,
          onSelected: (v) => onChanged(
            v == _all
                ? query.copyWith(clearSuggested: true)
                : query.copyWith(suggested: v == 'true'),
          ),
        ),
        _Pill(
          key: const Key('certificates_filter_validity'),
          label: tr('certificates.filter.validity'),
          value: query.validity ?? _all,
          options: validityOptions,
          onSelected: (v) => onChanged(
            v == _all
                ? query.copyWith(clearValidity: true)
                : query.copyWith(validity: v),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = value != CertificatesFilterPills._all;
    final color = active ? colors.primary : colors.foreground;
    return PopupMenuButton<String>(
      tooltip: label,
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final e in options.entries)
          PopupMenuItem(value: e.key, child: Text(e.value)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: AppRadius.pillRadius,
          border: Border.all(color: active ? colors.primary : colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr(
                'certificates.filter.pill',
                namedArgs: {'label': label, 'value': options[value] ?? ''},
              ),
              style: AppTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
