import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../components/ui/app_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../applications_constants.dart';
import '../applications_providers.dart';

/// Bottom sheet that edits status, stage, submitted-date range and sort order.
/// Pops with the new query when applied (UC-S3-MYAPP-05).
class ApplicationsFilterSheet extends StatefulWidget {
  const ApplicationsFilterSheet({super.key, required this.initial});

  final ApplicationsQuery initial;

  @override
  State<ApplicationsFilterSheet> createState() =>
      _ApplicationsFilterSheetState();
}

class _ApplicationsFilterSheetState extends State<ApplicationsFilterSheet> {
  late ApplicationsQuery _query = widget.initial;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final from = _query.submittedFrom;
    final to = _query.submittedTo;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: from != null && to != null
          ? DateTimeRange(start: from, end: to)
          : null,
    );
    if (range == null) return;
    setState(() {
      _query = _query.copyWith(
        submittedFrom: range.start,
        submittedTo: range.end,
      );
    });
  }

  String _rangeLabel() {
    final from = _query.submittedFrom;
    final to = _query.submittedTo;
    if (from == null || to == null) return tr('applications.range.any');
    String day(DateTime d) => d.toIso8601String().substring(0, 10);
    return '${day(from)} – ${day(to)}';
  }

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
              tr('applications.filter.title'),
              style: AppTypography.display(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
            heading('applications.filter.statusCaption'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in ApplicationConstants.statuses)
                  FilterChip(
                    label: Text(tr(ApplicationConstants.statusKey(status))),
                    selected: _query.statuses.contains(status),
                    onSelected: (on) => setState(() {
                      final next = {..._query.statuses};
                      on ? next.add(status) : next.remove(status);
                      _query = _query.copyWith(statuses: next);
                    }),
                  ),
              ],
            ),
            heading('applications.stageLabel'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final stage in ApplicationConstants.reviewStages)
                  ChoiceChip(
                    label: Text(tr('applications.stage.$stage')),
                    selected: _query.reviewStage == stage,
                    onSelected: (on) => setState(() {
                      _query = on
                          ? _query.copyWith(reviewStage: stage)
                          : _query.copyWith(clearReviewStage: true);
                    }),
                  ),
              ],
            ),
            heading('applications.filter.submitted'),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: _rangeLabel(),
                    variant: AppButtonVariant.outline,
                    onPressed: _pickRange,
                  ),
                ),
                if (_query.submittedFrom != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _query = _query.copyWith(clearDates: true);
                    }),
                    child: Text(tr('applications.filter.any')),
                  ),
                ],
              ],
            ),
            heading('applications.filter.sort'),
            Wrap(
              spacing: 8,
              children: [
                for (final order in const [
                  ApplicationConstants.orderDescending,
                  ApplicationConstants.orderAscending,
                ])
                  ChoiceChip(
                    label: Text(
                      tr(
                        order == ApplicationConstants.orderDescending
                            ? 'applications.sort.newest'
                            : 'applications.sort.oldest',
                      ),
                    ),
                    selected: _query.sortOrder == order,
                    onSelected: (_) => setState(() {
                      _query = _query.copyWith(sortOrder: order);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: tr('applications.clearFilters'),
                    variant: AppButtonVariant.outline,
                    onPressed: () => setState(() {
                      _query = ApplicationsQuery(search: _query.search);
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: tr('applications.filter.apply'),
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
