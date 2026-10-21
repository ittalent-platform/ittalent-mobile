import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../api/api_error.dart';
import '../../../components/common/app_empty_state.dart';
import '../../../components/common/app_error_state.dart';
import '../../../components/layout/screen_scaffold.dart';
import '../../../components/ui/app_button.dart';
import '../../../components/ui/app_card.dart';
import '../../../components/ui/app_skeleton.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'portfolio_constants.dart';
import 'portfolio_providers.dart';
import 'widgets/portfolio_form_sheet.dart';

/// UC-S4-PORT-04 list with UC-S4-PORT-01 create and UC-S4-PORT-03 delete.
class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter <
          PortfolioConstants.loadMoreThreshold) {
        ref.read(portfolioProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toast(String key, String name) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(tr(key, namedArgs: {'name': name}))));
  }

  Future<void> _add() async {
    final title = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const PortfolioFormSheet(),
    );
    if (title != null && mounted) _toast('portfolio.toast.added', title);
  }

  Future<void> _delete(PortfolioLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('portfolio.delete.title')),
        content: Text(
          tr('portfolio.delete.description', namedArgs: {'name': link.title}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(tr('portfolio.delete.keep')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(tr('portfolio.delete.confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(portfolioActionsProvider).delete(link);
      if (mounted) _toast('portfolio.toast.deleted', link.title);
    } on ApiError catch (e) {
      if (!mounted) return;
      // Changed or removed elsewhere: reload so the list shows the latest.
      if (e.code == PortfolioConstants.codeVersionConflict || e.isNotFound) {
        ref.invalidate(portfolioProvider);
        _toast('portfolio.toast.alreadyGone', link.title);
        return;
      }
      _toast('portfolio.errors.deleteFailed', link.title);
    } catch (_) {
      if (mounted) _toast('portfolio.errors.deleteFailed', link.title);
    }
  }

  Widget _skeleton() => ListView.separated(
    padding: const EdgeInsets.symmetric(vertical: 16),
    itemCount: 3,
    separatorBuilder: (context, index) => const SizedBox(height: 12),
    itemBuilder: (context, index) => const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 160, height: 18),
          SizedBox(height: 8),
          AppSkeleton(width: 220, height: 14),
        ],
      ),
    ),
  );

  Widget _footer(PortfolioListState data) {
    if (data.loadMoreFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(tr('portfolio.errors.loadMore')),
            const SizedBox(height: 8),
            AppButton(
              text: tr('portfolio.errors.retry'),
              variant: AppButtonVariant.outline,
              onPressed: ref.read(portfolioProvider.notifier).loadMore,
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

  Widget _card(PortfolioLink link) {
    final colors = context.colors;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => launchUrl(
                Uri.parse(link.url),
                mode: LaunchMode.externalApplication,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.title,
                    style: AppTypography.display(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    link.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      fontSize: 13,
                      color: colors.primary,
                    ),
                  ),
                  if (link.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      link.description!,
                      style: AppTypography.body(
                        fontSize: 13,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: tr('portfolio.delete.confirm'),
            icon: const Icon(LucideIcons.trash2, size: 18),
            onPressed: () => _delete(link),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final async = ref.watch(portfolioProvider);

    return ScreenScaffold(
      appBar: AppBar(
        title: Text(tr('portfolio.title')),
        actions: [
          IconButton(
            tooltip: tr('portfolio.add'),
            icon: const Icon(LucideIcons.plus, size: 20),
            onPressed: _add,
          ),
        ],
      ),
      body: async.when(
        skipLoadingOnReload: false,
        loading: _skeleton,
        error: (error, _) => AppErrorState(
          title: tr('portfolio.errors.loadTitle'),
          message: error is ApiError
              ? error.message
              : tr('portfolio.errors.loadDescription'),
          retryText: tr('portfolio.errors.retry'),
          onRetry: () => ref.invalidate(portfolioProvider),
        ),
        data: (data) {
          if (data.items.isEmpty) {
            return AppEmptyState(
              icon: const Icon(LucideIcons.link),
              title: tr('portfolio.empty.title'),
              description: tr('portfolio.empty.description'),
              actionText: tr('portfolio.add'),
              onAction: _add,
            );
          }
          return RefreshIndicator(
            color: colors.primary,
            onRefresh: () => ref.refresh(portfolioProvider.future),
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: data.items.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => index == data.items.length
                  ? _footer(data)
                  : _card(data.items[index]),
            ),
          );
        },
      ),
    );
  }
}
