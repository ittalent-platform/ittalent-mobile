import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../jobs_constants.dart';
import '../jobs_format.dart';
import '../jobs_query.dart';
import 'job_chip.dart';

/// The row under the search box: the dark "Filters" button, then quick
/// filters while nothing narrows the list, or the applied filters, each one
/// removed by tapping it.
class JobFilterBar extends StatelessWidget {
  const JobFilterBar({
    super.key,
    required this.query,
    required this.onOpenFilters,
    required this.onChanged,
  });

  final JobsQuery query;
  final VoidCallback onOpenFilters;
  final ValueChanged<JobsQuery> onChanged;

  /// "20M+", "Up to 40M" or "20–40M": the salary range as a chip.
  static String salaryLabel(JobsQuery query) {
    final min = query.salaryMin;
    final max = query.salaryMax;
    if (min != null && max != null) {
      return tr(
        'jobs.filter.salaryBetween',
        namedArgs: {'min': '$min', 'max': '$max'},
      );
    }
    if (min != null) {
      return tr('jobs.filter.salaryFrom', namedArgs: {'min': '$min'});
    }
    return tr('jobs.filter.salaryUpTo', namedArgs: {'max': '${max ?? 0}'});
  }

  /// A copy of [values] without [value]: the sets of a query never change
  /// after the fact.
  static Set<String> _without(Set<String> values, String value) =>
      values.where((e) => e != value).toSet();

  List<Widget> _quick() => [
    JobChip(
      label: JobFormat.cityLabel(JobConstants.cityHoChiMinh),
      onTap: () =>
          onChanged(query.copyWith(cities: {JobConstants.cityHoChiMinh})),
    ),
    JobChip(
      label: JobFormat.employmentLabel(JobConstants.typeRemote),
      onTap: () => onChanged(query.copyWith(types: {JobConstants.typeRemote})),
    ),
    JobChip(
      label: JobFormat.levelLabel(JobConstants.quickLevel),
      onTap: () => onChanged(query.copyWith(levels: {JobConstants.quickLevel})),
    ),
    JobChip(
      label: tr(
        'jobs.filter.salaryFrom',
        namedArgs: {'min': '${JobConstants.quickSalaryMin}'},
      ),
      onTap: () =>
          onChanged(query.copyWith(salaryMin: JobConstants.quickSalaryMin)),
    ),
  ];

  List<Widget> _applied() => [
    if (query.search.trim().isNotEmpty)
      JobChip(
        label: tr(
          'jobs.filter.keyword',
          namedArgs: {'text': query.search.trim()},
        ),
        showClose: true,
        onTap: () => onChanged(query.copyWith(search: '')),
      ),
    for (final city in query.cities)
      JobChip(
        label: JobFormat.cityLabel(city),
        showClose: true,
        onTap: () =>
            onChanged(query.copyWith(cities: _without(query.cities, city))),
      ),
    for (final type in query.types)
      JobChip(
        label: JobFormat.employmentLabel(type),
        showClose: true,
        onTap: () =>
            onChanged(query.copyWith(types: _without(query.types, type))),
      ),
    for (final level in query.levels)
      JobChip(
        label: JobFormat.levelLabel(level),
        showClose: true,
        onTap: () =>
            onChanged(query.copyWith(levels: _without(query.levels, level))),
      ),
    if (query.hasSalaryRange)
      JobChip(
        label: salaryLabel(query),
        showClose: true,
        onTap: () => onChanged(query.copyWith(clearSalary: true)),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final chips = query.isFiltered ? _applied() : _quick();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FiltersButton(
            label: query.filterCount > 0
                ? tr(
                    'jobs.filter.titleCount',
                    namedArgs: {'count': '${query.filterCount}'},
                  )
                : tr('jobs.filter.title'),
            onTap: onOpenFilters,
          ),
          for (final chip in chips) ...[const SizedBox(width: 8), chip],
        ],
      ),
    );
  }
}

/// The dark "Filters" pill that opens every filter at once.
class _FiltersButton extends StatelessWidget {
  const _FiltersButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.foreground,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: JobChip.height),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.slidersHorizontal,
                  size: 16,
                  color: colors.background,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.background,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
