import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/layout/screen_scaffold.dart';
import '../../../components/ui/app_input.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'jobs_constants.dart';
import 'jobs_format.dart';
import 'jobs_models.dart';
import 'jobs_providers.dart';
import 'jobs_query.dart';
import 'widgets/job_chip.dart';

/// The search page: suggestions while typing, recent searches and popular
/// keywords. Pops with the chosen keyword (empty clears it), or with null
/// when cancelled.
class JobSearchScreen extends ConsumerStatefulWidget {
  const JobSearchScreen({super.key, this.initial = ''});

  final String initial;

  static Future<String?> open(BuildContext context, {String initial = ''}) =>
      Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => JobSearchScreen(initial: initial)),
      );

  @override
  ConsumerState<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends ConsumerState<JobSearchScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  static const double rowIconSize = 18;
  static const double rowHeight = 50;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Why the text cannot be searched, or null when it can.
  String? _errorOf(String value) {
    if (value.length > JobConstants.searchMaxLength) {
      return tr(
        'home.search.keywordTooLong',
        namedArgs: {'max': '${JobConstants.searchMaxLength}'},
      );
    }
    if (!JobConstants.searchPattern.hasMatch(value)) {
      return tr('jobs.search.invalid');
    }
    return null;
  }

  void _submit(String keyword) {
    final text = keyword.trim();
    if (_errorOf(text) != null) return;
    ref.read(recentJobSearchesProvider.notifier).add(text);
    Navigator.of(context).pop(text);
  }

  Widget _row({
    required IconData icon,
    required Widget title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: rowHeight),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: Row(
          children: [
            Icon(icon, size: rowIconSize, color: colors.mutedForeground),
            const SizedBox(width: 12),
            Expanded(child: title),
            ?trailing,
          ],
        ),
      ),
    );
  }

  Widget _caption(String text, {Widget? trailing}) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: AppTypography.body(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.72,
                color: colors.mutedForeground,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  List<Widget> _suggestions(String text) {
    final colors = context.colors;
    final jobs =
        ref.watch(publicJobsProvider).value?.jobs ?? const <JobPosting>[];
    final suggestions = JobSearch.suggest(jobs, text);
    final base = AppTypography.body(fontSize: 16, color: colors.foreground);
    if (suggestions.isEmpty) {
      return [
        _row(
          icon: LucideIcons.search,
          title: Text(
            tr('jobs.search.for', namedArgs: {'text': text}),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: base,
          ),
          onTap: () => _submit(text),
        ),
      ];
    }
    return [
      for (final suggestion in suggestions)
        _row(
          icon: LucideIcons.search,
          title: _highlighted(suggestion.title, text, base),
          trailing: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              JobFormat.countText('jobs.count', suggestion.count),
              style: AppTypography.body(
                fontSize: 13,
                color: colors.mutedForeground,
              ),
            ),
          ),
          onTap: () => _submit(suggestion.title),
        ),
    ];
  }

  /// [title] with the part that matches [text] in bold. The match ignores
  /// case and accents, and both texts keep their length when folded.
  Widget _highlighted(String title, String text, TextStyle base) {
    final folded = JobSearch.fold(title);
    final needle = JobSearch.fold(text.trim());
    final start = folded.indexOf(needle);
    final end = start + needle.length;
    if (start < 0 || end > title.length) {
      return Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: base,
      );
    }
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: title.substring(0, start)),
          TextSpan(
            text: title.substring(start, end),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: title.substring(end)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  List<Widget> _recent(List<String> recent) {
    final colors = context.colors;
    if (recent.isEmpty) return const [];
    return [
      _caption(
        tr('jobs.search.recent'),
        trailing: InkWell(
          onTap: ref.read(recentJobSearchesProvider.notifier).clear,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              tr('jobs.search.clearRecent'),
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.fgLink,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 6),
      for (final keyword in recent)
        _row(
          icon: LucideIcons.clock,
          title: Text(
            keyword,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body(fontSize: 16, color: colors.foreground),
          ),
          trailing: IconButton(
            tooltip: tr('actions.close'),
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                ref.read(recentJobSearchesProvider.notifier).remove(keyword),
            icon: Icon(
              LucideIcons.x,
              size: rowIconSize,
              color: colors.mutedForeground,
            ),
          ),
          onTap: () => _submit(keyword),
        ),
    ];
  }

  List<Widget> _popular() => [
    _caption(tr('jobs.search.popular')),
    const SizedBox(height: 12),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final keyword in JobConstants.popularKeywords)
          JobChip(label: keyword, onTap: () => _submit(keyword)),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = _controller.text.trim();
    final error = _errorOf(_controller.text);
    final recent = ref.watch(recentJobSearchesProvider);

    return ScreenScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppInput(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  hintText: tr('home.search.keywordPlaceholder'),
                  errorText: error,
                  prefixIcon: const Icon(LucideIcons.search, size: rowIconSize),
                  suffixIcon: text.isEmpty
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              '${_controller.text.length}/${JobConstants.searchMaxLength}',
                              style: AppTypography.body(
                                fontSize: 12,
                                color: colors.mutedForeground,
                              ),
                            ),
                          ),
                        ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: _submit,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  tr('actions.cancel'),
                  style: AppTypography.body(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colors.fgLink,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: error != null
                ? const SizedBox.shrink()
                : ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      if (text.isNotEmpty) ..._suggestions(text),
                      ..._recent(recent),
                      ..._popular(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
