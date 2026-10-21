import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../api/api_error.dart';
import '../../../components/common/app_empty_state.dart';
import '../../../components/common/app_error_state.dart';
import '../../../components/layout/screen_scaffold.dart';
import '../../../components/ui/app_button.dart';
import '../../../components/ui/app_card.dart';
import '../../../components/ui/app_input.dart';
import '../../../components/ui/app_skeleton.dart';
import '../../../theme/app_colors.dart';
import 'certificates_constants.dart';
import 'certificates_providers.dart';
import 'widgets/certificate_card.dart';
import 'widgets/certificates_filter_sheet.dart';

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

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<CertificatesQuery>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          CertificatesFilterSheet(initial: ref.read(certificatesQueryProvider)),
    );
    if (result != null) {
      ref.read(certificatesQueryProvider.notifier).update(result);
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
      appBar: AppBar(
        title: Text(tr('certificates.title')),
        actions: [
          IconButton(
            tooltip: tr('certificates.filter.title'),
            icon: Icon(
              LucideIcons.listFilter,
              size: 20,
              color: query.suggested != null || query.validity != null
                  ? colors.primary
                  : null,
            ),
            onPressed: _openFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: AppInput(
              controller: _searchController,
              hintText: tr('certificates.search.placeholder'),
              errorText: _searchError,
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: async.when(
              skipLoadingOnReload: false,
              loading: _skeleton,
              error: (error, _) => AppErrorState(
                title: tr('certificates.errors.loadTitle'),
                message: error is ApiError
                    ? error.message
                    : tr('certificates.errors.loadDescription'),
                retryText: tr('certificates.errors.retry'),
                onRetry: () => ref.invalidate(certificatesProvider),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: data.items.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) => index == data.items.length
                        ? _footer(data)
                        : CertificateCard(item: data.items[index]),
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
