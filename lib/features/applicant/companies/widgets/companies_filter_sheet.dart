import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../components/ui/app_button.dart';
import '../../../../components/ui/app_skeleton.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_typography.dart';
import '../companies_constants.dart';
import '../companies_format.dart';
import '../companies_providers.dart';

/// The sheet behind "Filters" and the Industry, Size and City pills: industry
/// and size take several choices, a city one. "Show N companies" counts what
/// the choices match before they are applied, and pops with the new query.
class CompaniesFilterSheet extends ConsumerStatefulWidget {
  const CompaniesFilterSheet({
    super.key,
    required this.initial,
    required this.groups,
  });

  final CompaniesQuery initial;

  /// What the sheet offers: one group from a pill, all three from "Filters".
  final Set<CompanyFilterGroup> groups;

  @override
  ConsumerState<CompaniesFilterSheet> createState() =>
      _CompaniesFilterSheetState();
}

class _CompaniesFilterSheetState extends ConsumerState<CompaniesFilterSheet> {
  late Set<String> _industries = {...widget.initial.industries};
  late Set<String> _sizes = {...widget.initial.sizes};
  late String? _city = widget.initial.city;

  CompaniesQuery _result() => CompaniesQuery(
    search: widget.initial.search,
    industries: _industries,
    sizes: _sizes,
    city: _city,
  );

  bool get _single => widget.groups.length == 1;

  bool get _hasSelection =>
      _industries.isNotEmpty || _sizes.isNotEmpty || _city != null;

  String get _title => _single
      ? tr('companies.filter.${widget.groups.single.name}')
      : tr('companies.filter.title');

  void _reset() => setState(() {
    if (widget.groups.contains(CompanyFilterGroup.industry)) _industries = {};
    if (widget.groups.contains(CompanyFilterGroup.size)) _sizes = {};
    if (widget.groups.contains(CompanyFilterGroup.city)) _city = null;
  });

  /// A new set each time: a query is the key of the count request, so the
  /// sets inside it must never change after the fact.
  Set<String> _toggled(Set<String> values, String value) =>
      values.contains(value)
      ? ({...values}..remove(value))
      : {...values, value};

  Widget _caption(String key) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
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
  }

  Widget _industryChips() {
    final industries = ref.watch(companyIndustriesProvider);
    return industries.when(
      loading: () => const Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          AppSkeleton(
            width: 90,
            height: 40,
            borderRadius: AppRadius.pillRadius,
          ),
          AppSkeleton(
            width: 110,
            height: 40,
            borderRadius: AppRadius.pillRadius,
          ),
          AppSkeleton(
            width: 80,
            height: 40,
            borderRadius: AppRadius.pillRadius,
          ),
        ],
      ),
      error: (_, _) => Row(
        children: [
          Expanded(
            child: Text(
              tr('companies.filter.industriesFailed'),
              style: AppTypography.body(
                fontSize: 14,
                color: context.colors.mutedForeground,
              ),
            ),
          ),
          AppButton(
            text: tr('errorState.retry'),
            variant: AppButtonVariant.outline,
            size: AppButtonSize.sm,
            onPressed: () => ref.invalidate(companyIndustriesProvider),
          ),
        ],
      ),
      data: (options) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in options)
            _FilterChip(
              label: option.industry,
              selected: _industries.contains(option.industry),
              onTap: () => setState(
                () => _industries = _toggled(_industries, option.industry),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sizeChips() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final size in CompanyConstants.sizes)
        _FilterChip(
          label: CompanyFormat.sizeRange(size),
          selected: _sizes.contains(size),
          onTap: () => setState(() => _sizes = _toggled(_sizes, size)),
        ),
    ],
  );

  Widget _cityChips() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final city in CompanyConstants.cities)
        _FilterChip(
          label: city,
          selected: _city == city,
          onTap: () => setState(() => _city = _city == city ? null : city),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = ref.watch(companiesCountProvider(_result())).value;
    final groups = widget.groups;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _title,
                    style: AppTypography.display(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                    ),
                  ),
                ),
                if (_hasSelection)
                  TextButton(
                    onPressed: _reset,
                    child: Text(
                      tr('companies.filter.reset'),
                      style: AppTypography.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.fgLink,
                      ),
                    ),
                  ),
              ],
            ),
            if (groups.contains(CompanyFilterGroup.industry)) ...[
              if (!_single)
                _caption('companies.filter.industry')
              else
                const SizedBox(height: 14),
              _industryChips(),
            ],
            if (groups.contains(CompanyFilterGroup.size)) ...[
              if (!_single)
                _caption('companies.filter.size')
              else
                const SizedBox(height: 14),
              _sizeChips(),
            ],
            if (groups.contains(CompanyFilterGroup.city)) ...[
              if (!_single)
                _caption('companies.filter.city')
              else
                const SizedBox(height: 14),
              _cityChips(),
            ],
            const SizedBox(height: 20),
            AppButton(
              text: count == null
                  ? tr('companies.filter.showAll')
                  : CompanyFormat.countText('companies.filter.show', count),
              isFullWidth: true,
              size: AppButtonSize.lg,
              onPressed: () => Navigator.of(context).pop(_result()),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double height = 40;
  static const double selectedBorderAlpha = 0.4;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.statusPeachBg : colors.card,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected
                ? colors.primary.withValues(alpha: selectedBorderAlpha)
                : colors.border,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? colors.fgLink : colors.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
