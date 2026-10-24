import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/layout/screen_scaffold.dart';
import '../../../../components/ui/app_input.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../jobs_constants.dart';
import '../jobs_format.dart';
import '../jobs_models.dart';
import '../jobs_providers.dart';
import '../jobs_query.dart';

/// Full-screen search: suggestions while typing, recent searches otherwise.
/// Pops with the chosen keyword (empty clears it), or null when cancelled.
class JobSearchPage extends ConsumerStatefulWidget {
  const JobSearchPage({super.key, this.initial = ''});

  final String initial;

  static Future<String?> open(BuildContext context, {String initial = ''}) =>
      Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => JobSearchPage(initial: initial)),
      );

  @override
  ConsumerState<JobSearchPage> createState() => _JobSearchPageState();
}

class _JobSearchPageState extends ConsumerState<JobSearchPage> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  static const double rowIconSize = 18;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _text => _controller.text.trim();

  /// Why the text cannot be searched, or null when it can.
  String? _errorOf(String value) {
    if (value.length > JobConstants.searchMaxLength) {
      return tr(
        'jobs.search.tooLong',
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _suggestions(String text) {
    final colors = context.colors;
    final jobs =
        ref.watch(publicJobsProvider).value?.jobs ?? const <JobPosting>[];
    final suggestions = JobSearch.suggest(jobs, text);
    final base = AppTypography.body(fontSize: 15, color: colors.foreground);
    return ListView(
      children: [
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
        for (final suggestion in suggestions)
          _row(
            icon: LucideIcons.search,
            title: _highlighted(suggestion.title, text, base),
            trailing: Text(
              JobFormat.countText('jobs.count', suggestion.count),
              style: AppTypography.body(
                fontSize: 13,
                color: colors.mutedForeground,
              ),
            ),
            onTap: () => _submit(suggestion.title),
          ),
      ],
    );
  }

  /// [title] with the part that matches [text] in bold.
  Widget _highlighted(String title, String text, TextStyle base) {
    final start = title.toLowerCase().indexOf(text.toLowerCase());
    if (start < 0 || start + text.length > title.length) {
      return Text(title, style: base);
    }
    final end = start + text.length;
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

  Widget _recent(List<String> recent) {
    final colors = context.colors;
    if (recent.isEmpty) return const SizedBox.shrink();
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tr('jobs.search.recent').toUpperCase(),
                  style: AppTypography.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: colors.mutedForeground,
                  ),
                ),
              ),
              TextButton(
                onPressed: ref.read(recentJobSearchesProvider.notifier).clear,
                child: Text(
                  tr('jobs.search.clearRecent'),
                  style: AppTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final keyword in recent)
          _row(
            icon: LucideIcons.clock,
            title: Text(
              keyword,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(fontSize: 15, color: colors.foreground),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = _text;
    final error = _errorOf(_controller.text);
    final recent = ref.watch(recentJobSearchesProvider);

    return ScreenScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: error != null
                ? const SizedBox.shrink()
                : text.isEmpty
                ? _recent(recent)
                : _suggestions(text),
          ),
        ],
      ),
    );
  }
}
