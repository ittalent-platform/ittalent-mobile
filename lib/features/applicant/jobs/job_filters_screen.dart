import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/ui/app_button.dart';
import '../../../components/ui/app_checkbox.dart';
import '../../../components/ui/app_input.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'jobs_constants.dart';
import 'jobs_format.dart';
import 'jobs_providers.dart';
import 'jobs_query.dart';
import 'widgets/job_chip.dart';

/// The full-screen filters behind "Filters": job type and level take several
/// choices, the salary a range in millions of VND a month. "Show N jobs"
/// counts what the choices match before they are applied, and pops with the
/// new query; the close button pops without one.
class JobFiltersScreen extends ConsumerStatefulWidget {
  const JobFiltersScreen({super.key, required this.initial});

  final JobsQuery initial;

  /// Opens the screen above the tab bar and returns the chosen query, or null
  /// when it was closed.
  static Future<JobsQuery?> open(BuildContext context, JobsQuery initial) =>
      Navigator.of(context, rootNavigator: true).push<JobsQuery>(
        MaterialPageRoute(builder: (_) => JobFiltersScreen(initial: initial)),
      );

  @override
  ConsumerState<JobFiltersScreen> createState() => _JobFiltersScreenState();
}

class _JobFiltersScreenState extends ConsumerState<JobFiltersScreen> {
  late Set<String> _types = {...widget.initial.types};
  late Set<String> _levels = {...widget.initial.levels};
  late Set<String> _cities = {...widget.initial.cities};
  late bool _includeNegotiable = widget.initial.includeNegotiable;
  late final TextEditingController _min = TextEditingController(
    text: widget.initial.salaryMin?.toString() ?? '',
  );
  late final TextEditingController _max = TextEditingController(
    text: widget.initial.salaryMax?.toString() ?? '',
  );

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  int? _number(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  JobsQuery _draft() {
    final min = _number(_min);
    final max = _number(_max);
    return JobsQuery(
      search: widget.initial.search,
      types: _types,
      levels: _levels,
      cities: _cities,
      salaryMin: min,
      salaryMax: max,
      includeNegotiable: _includeNegotiable,
      sort: widget.initial.sort,
    );
  }

  /// A new set each time, so a query never changes after the fact.
  Set<String> _toggled(Set<String> values, String value) =>
      values.contains(value)
      ? values.where((e) => e != value).toSet()
      : {...values, value};

  void _reset() => setState(() {
    _types = {};
    _levels = {};
    _cities = {};
    _includeNegotiable = true;
    _min.clear();
    _max.clear();
  });

  Widget _section({
    required String title,
    required Widget child,
    bool last = false,
  }) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _chips(List<JobChip> chips) =>
      Wrap(spacing: 8, runSpacing: 8, children: chips);

  Widget _topBar() {
    final colors = context.colors;
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: tr('actions.close'),
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(LucideIcons.x, size: 24, color: colors.foreground),
            ),
          ),
          Text(
            tr('jobs.filter.title'),
            style: AppTypography.body(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colors.foreground,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _reset,
              child: Text(
                tr('jobs.filter.reset'),
                style: AppTypography.body(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.fgLink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _salaryField(TextEditingController controller, String labelKey) {
    return AppInput(
      controller: controller,
      label: tr(labelKey),
      hintText: tr('jobs.filter.any'),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(JobConstants.salaryDigits),
      ],
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _salary(bool valid) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _salaryField(_min, 'jobs.filter.min')),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 38, 10, 0),
              child: Text(
                '–',
                style: AppTypography.body(
                  fontSize: 16,
                  color: colors.mutedForeground,
                ),
              ),
            ),
            Expanded(child: _salaryField(_max, 'jobs.filter.max')),
          ],
        ),
        if (!valid) ...[
          const SizedBox(height: 8),
          Text(
            tr('jobs.filter.salaryOrder'),
            style: AppTypography.body(fontSize: 13, color: colors.destructive),
          ),
        ],
        const SizedBox(height: 14),
        AppCheckbox(
          value: _includeNegotiable,
          onChanged: (value) =>
              setState(() => _includeNegotiable = value ?? true),
          child: Text(
            tr('jobs.filter.includeNegotiable'),
            style: AppTypography.body(
              fontSize: 14.5,
              height: 1.45,
              color: colors.foreground,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(String label, VoidCallback? onPressed) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: AppButton(
          text: label,
          isFullWidth: true,
          size: AppButtonSize.lg,
          onPressed: onPressed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final draft = _draft();
    final valid = draft.hasValidSalaryRange;
    final jobs = ref.watch(publicJobsProvider).value?.jobs;
    final count = jobs == null ? null : draft.apply(jobs).length;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section(
                        title: tr('jobs.filter.jobType'),
                        child: _chips([
                          for (final type in JobConstants.employmentTypes)
                            JobChip(
                              label: JobFormat.employmentLabel(type),
                              selected: _types.contains(type),
                              onTap: () => setState(
                                () => _types = _toggled(_types, type),
                              ),
                            ),
                        ]),
                      ),
                      _section(
                        title: tr('jobs.filter.level'),
                        child: _chips([
                          for (final level in JobConstants.levels)
                            JobChip(
                              label: JobFormat.levelLabel(level),
                              selected: _levels.contains(level),
                              onTap: () => setState(
                                () => _levels = _toggled(_levels, level),
                              ),
                            ),
                        ]),
                      ),
                      _section(
                        title: tr('jobs.filter.salary'),
                        last: true,
                        child: _salary(valid),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _bottomBar(
              count == null
                  ? tr('jobs.filter.showAll')
                  : JobFormat.countText('jobs.filter.show', count),
              valid ? () => Navigator.of(context).pop(draft) : null,
            ),
          ],
        ),
      ),
    );
  }
}
