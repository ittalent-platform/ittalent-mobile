import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../components/ui/app_badge.dart';
import '../../../../components/ui/app_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_typography.dart';
import '../applications_constants.dart';
import '../applications_providers.dart';

/// Radio value of "Any time" (no submitted-date filter).
const String _anyTime = '';

/// "Filter applications" sheet: multi-select statuses and a submitted-date
/// preset. Pops with the new query when applied (UC-S3-MYAPP-05).
class ApplicationsFilterSheet extends ConsumerStatefulWidget {
  const ApplicationsFilterSheet({super.key, required this.initial});

  final ApplicationsQuery initial;

  @override
  ConsumerState<ApplicationsFilterSheet> createState() =>
      _ApplicationsFilterSheetState();
}

class _ApplicationsFilterSheetState
    extends ConsumerState<ApplicationsFilterSheet> {
  final _now = DateTime.now();
  late Set<String> _statuses = {...widget.initial.statuses};
  late String _preset =
      ApplicationConstants.presetOf(widget.initial.submittedFrom, _now) ??
      _anyTime;

  DateTime? get _from => _preset == _anyTime
      ? null
      : ApplicationConstants.presetStart(_preset, _now);

  ApplicationsQuery _result() {
    final base = widget.initial.copyWith(statuses: _statuses, clearDates: true);
    return _from == null ? base : base.copyWith(submittedFrom: _from);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final counts = ref
        .watch(
          applicationStatusCountsProvider((
            search: widget.initial.search.trim(),
            submittedFrom: _from,
          )),
        )
        .value;
    final matching = counts?.entries
        .where((e) => _statuses.isEmpty || _statuses.contains(e.key))
        .fold<int>(0, (sum, e) => sum + e.value);

    Widget caption(String key) => Padding(
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

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('applications.filter.title'),
              style: AppTypography.display(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
            caption('applications.filter.statusCaption'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in ApplicationConstants.statuses)
                  _StatusChip(
                    status: status,
                    selected: _statuses.contains(status),
                    onTap: () => setState(() {
                      _statuses = {..._statuses};
                      if (!_statuses.remove(status)) _statuses.add(status);
                    }),
                  ),
              ],
            ),
            caption('applications.filter.submittedCaption'),
            RadioGroup<String>(
              groupValue: _preset,
              onChanged: (value) => setState(() => _preset = value!),
              child: Column(
                children: [
                  for (final preset in [
                    _anyTime,
                    ...ApplicationConstants.submittedPresets,
                  ]) ...[
                    RadioListTile<String>(
                      value: preset,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      activeColor: colors.primary,
                      title: Text(
                        tr(
                          'applications.range.${preset.isEmpty ? 'any' : preset}',
                        ),
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
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: tr('applications.filter.reset'),
                    variant: AppButtonVariant.outline,
                    onPressed: () => setState(() {
                      _statuses = {};
                      _preset = _anyTime;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    text: matching == null
                        ? tr('applications.filter.showAll')
                        : ApplicationConstants.countText(
                            'applications.filter.showResults',
                            matching,
                          ),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final String status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillRadius,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: AppRadius.pillRadius,
            border: Border.all(
              color: selected ? context.colors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: AppBadge(
            label: tr(ApplicationConstants.statusKey(status)),
            tone: ApplicationConstants.badgeToneForStatus(status),
          ),
        ),
      ),
    );
  }
}
