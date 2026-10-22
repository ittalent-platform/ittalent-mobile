import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../api/api_error.dart';
import '../../../components/common/app_empty_state.dart';
import '../../../components/common/app_toast.dart';
import '../../../components/layout/screen_scaffold.dart';
import '../../../components/ui/app_button.dart';
import '../../../components/ui/app_card.dart';
import '../../../components/ui/app_input.dart';
import '../../../components/ui/app_skeleton.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'certificates_constants.dart';
import 'certificates_providers.dart';
import 'widgets/bold_markup_text.dart';
import 'widgets/certificate_card.dart';
import 'widgets/certificate_form_page.dart';
import 'widgets/certificate_sheets.dart';
import 'widgets/certificates_filter_pills.dart';

/// UC-S4-CERT-04 list with UC-S4-CERT-06 search and filters.
class CertificatesScreen extends ConsumerStatefulWidget {
  const CertificatesScreen({super.key});

  @override
  ConsumerState<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends ConsumerState<CertificatesScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String? _searchError;
  // Certificates whose switch is being saved; their switch waits.
  final Set<String> _saving = {};
  // The certificate just added, outlined until the next add or edit.
  String? _highlightId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter <
          CertificateConstants.loadMoreThreshold) {
        ref.read(certificatesProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Blank and over-long keywords are rejected before any request.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final keyword = value.trim();
    String? error;
    if (value.isNotEmpty && keyword.isEmpty) {
      error = tr('applications.errors.keywordBlank');
    } else if (keyword.length > CertificateConstants.searchMaxLength) {
      error = tr(
        'certificates.search.tooLong',
        namedArgs: {'max': '${CertificateConstants.searchMaxLength}'},
      );
    }
    setState(() => _searchError = error);
    if (error != null) return;
    _debounce = Timer(CertificateConstants.searchDebounce, () {
      ref
          .read(certificatesQueryProvider.notifier)
          .update(
            ref.read(certificatesQueryProvider).copyWith(search: keyword),
          );
    });
  }

  void _toast(String message, {bool error = false, SnackBarAction? action}) =>
      showAppToast(
        ScaffoldMessenger.of(context),
        message,
        error: error,
        action: action,
      );

  /// Saves the switch at once; the toast offers Undo (which itself is not undoable).
  Future<void> _setSuggested(
    CertificateLink item,
    bool value, {
    bool undoable = true,
  }) async {
    setState(() => _saving.add(item.id));
    try {
      final saved = await ref
          .read(certificatesProvider.notifier)
          .setSuggested(item, value);
      if (!mounted) return;
      _toast(
        tr(
          value
              ? 'certificates.toast.suggested'
              : 'certificates.toast.unsuggested',
        ),
        action: undoable
            ? SnackBarAction(
                label: tr('certificates.toast.undo'),
                onPressed: () => _setSuggested(saved, !value, undoable: false),
              )
            : null,
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      if (e.isConflict) {
        if (await showCertificateConflictSheet(context)) {
          ref.invalidate(certificatesProvider);
        }
      } else if (e.isNotFound) {
        ref.invalidate(certificatesProvider);
        _toast(tr('certificates.gone.title'), error: true);
      } else {
        _toast(tr('certificates.errors.switchFailed'), error: true);
      }
    } finally {
      if (mounted) setState(() => _saving.remove(item.id));
    }
  }

  Future<void> _openLink(CertificateLink item) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(item.url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (!opened && mounted) {
      _toast(
        tr('certificates.linkFailed', namedArgs: {'domain': item.domain}),
        error: true,
      );
    }
  }

  Future<void> _openMenu(CertificateLink item) async {
    final action = await showCertificateMenu(context, item);
    if (!mounted || action == null) return;
    switch (action) {
      case CertificateMenuAction.openLink:
        await _openLink(item);
      case CertificateMenuAction.edit:
        await _openForm(item);
      case CertificateMenuAction.delete:
        await _delete(item);
    }
  }

  Future<void> _openForm([CertificateLink? existing]) async {
    final result = await CertificateFormPage.open(context, existing);
    if (result == null || !mounted) return;
    setState(() => _highlightId = existing == null ? result.link.id : null);
    _toast(
      result.suggestFailed
          ? tr('certificates.errors.switchFailed')
          : tr(
              existing == null
                  ? 'certificates.toast.added'
                  : 'certificates.toast.saved',
              namedArgs: {'name': result.link.name},
            ),
      error: result.suggestFailed,
    );
  }

  Future<void> _delete(CertificateLink item) async {
    if (!await showCertificateDeleteSheet(context, item) || !mounted) return;
    try {
      await ref.read(certificateActionsProvider).delete(item);
      if (mounted) {
        _toast(
          tr('certificates.toast.deleted', namedArgs: {'name': item.name}),
        );
      }
    } on ApiError catch (e) {
      if (!mounted) return;
      if (e.isConflict) {
        if (await showCertificateConflictSheet(context)) {
          ref.invalidate(certificatesProvider);
        }
      } else if (e.isNotFound) {
        ref.invalidate(certificatesProvider);
        _toast(tr('certificates.gone.title'), error: true);
      } else {
        _toast(tr('certificates.errors.deleteFailed'), error: true);
      }
    }
  }

  void _clearAll() {
    _searchController.clear();
    setState(() => _searchError = null);
    ref.read(certificatesQueryProvider.notifier).clear();
  }

  Widget _skeleton() => ListView.separated(
    padding: const EdgeInsets.symmetric(vertical: 16),
    itemCount: 4,
    separatorBuilder: (context, index) => const SizedBox(height: 12),
    itemBuilder: (context, index) => const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 160, height: 18),
          SizedBox(height: 8),
          AppSkeleton(width: 120, height: 14),
        ],
      ),
    ),
  );

  Widget _summary(BuildContext context, int count) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(LucideIcons.send, size: 14, color: colors.mutedForeground),
        const SizedBox(width: 8),
        Expanded(
          child: BoldMarkupText(
            tr(
              count == 1
                  ? 'certificates.suggestedSummary_one'
                  : 'certificates.suggestedSummary_other',
              namedArgs: {'count': '$count'},
            ),
            style: AppTypography.body(
              fontSize: 13,
              color: colors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }

  Widget _footer(CertificatesListState data) {
    if (data.loadMoreFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(tr('certificates.loadMore')),
            const SizedBox(height: 8),
            AppButton(
              text: tr('certificates.errors.retry'),
              variant: AppButtonVariant.outline,
              onPressed: ref.read(certificatesProvider.notifier).loadMore,
            ),
          ],
        ),
      );
    }
    if (data.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final query = ref.watch(certificatesQueryProvider);
    final async = ref.watch(certificatesProvider);

    return ScreenScaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: tr('certificates.add'),
        shape: const CircleBorder(),
        backgroundColor: colors.primary,
        foregroundColor: colors.primaryForeground,
        onPressed: _openForm,
        child: const Icon(LucideIcons.plus),
      ),
      appBar: AppBar(
        leadingWidth: 96,
        leading: Navigator.of(context).canPop()
            ? TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: colors.primary),
                icon: const Icon(LucideIcons.chevronLeft, size: 20),
                label: Text(tr('certificates.back')),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('certificates.title'),
            style: AppTypography.display(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 12),
          AppInput(
            controller: _searchController,
            hintText: tr('certificates.search.placeholder'),
            errorText: _searchError,
            prefixIcon: const Icon(LucideIcons.search, size: 18),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 10),
          CertificatesFilterPills(
            query: query,
            onChanged: ref.read(certificatesQueryProvider.notifier).update,
          ),
          Expanded(
            child: async.when(
              skipLoadingOnReload: false,
              loading: _skeleton,
              error: (error, _) => AppEmptyState(
                icon: const Icon(LucideIcons.triangleAlert),
                title: tr('certificates.errors.loadTitle'),
                description: tr('certificates.errors.loadDescription'),
                actionText: tr('certificates.errors.retry'),
                onAction: () => ref.invalidate(certificatesProvider),
              ),
              data: (data) {
                if (data.items.isEmpty) {
                  return query.isFiltered
                      ? AppEmptyState(
                          icon: const Icon(LucideIcons.searchX),
                          title: query.search.isEmpty
                              ? tr('applications.noMatches')
                              : tr(
                                  'certificates.search.noMatch',
                                  namedArgs: {'term': query.search},
                                ),
                          description: tr(
                            'certificates.search.noMatchDescription',
                          ),
                          actionText: tr('certificates.filter.clear'),
                          onAction: _clearAll,
                        )
                      // No Add button here: the + in the corner already adds.
                      : AppEmptyState(
                          icon: const Icon(LucideIcons.award),
                          title: tr('certificates.empty.title'),
                          description: tr('certificates.empty.description'),
                        );
                }
                return RefreshIndicator(
                  color: colors.primary,
                  onRefresh: () => ref.refresh(certificatesProvider.future),
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 12, bottom: 96),
                    itemCount: data.items.length + 2,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _summary(context, data.suggestedTotal);
                      }
                      if (index > data.items.length) return _footer(data);
                      final item = data.items[index - 1];
                      return CertificateCard(
                        item: item,
                        onOpenLink: () => _openLink(item),
                        onMore: () => _openMenu(item),
                        highlighted: item.id == _highlightId,
                        onSuggestedChanged: _saving.contains(item.id)
                            ? null
                            : (value) => _setSuggested(item, value),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
