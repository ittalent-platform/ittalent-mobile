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
import '../../../components/ui/app_skeleton.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'portfolio_constants.dart';
import 'portfolio_providers.dart';
import 'widgets/portfolio_card.dart';
import 'widgets/portfolio_form_page.dart';
import 'widgets/portfolio_sheets.dart';

/// UC-S4-PORT-04 list with UC-S4-PORT-01 create and UC-S4-PORT-03 delete.
class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  final _scrollController = ScrollController();
  // The link just added, outlined until the next add.
  String? _highlightId;

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

  void _toast(String key, String name, {bool error = false}) => showAppToast(
    ScaffoldMessenger.of(context),
    tr(key, namedArgs: {'name': name}),
    error: error,
  );

  Future<void> _add() async {
    final link = await PortfolioFormPage.open(context);
    if (link == null || !mounted) return;
    setState(() => _highlightId = link.id);
    _toast('portfolio.toast.added', link.title);
  }

  Future<void> _openLink(PortfolioLink link) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(link.url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (!opened && mounted) {
      _toast('portfolio.linkFailed', link.domain, error: true);
    }
  }

  Future<void> _openMenu(PortfolioLink link) async {
    final action = await showPortfolioMenu(context, link);
    if (!mounted) return;
    switch (action) {
      case PortfolioMenuAction.openLink:
        await _openLink(link);
      case PortfolioMenuAction.delete:
        await _delete(link);
      case null:
        break;
    }
  }

  Future<void> _delete(PortfolioLink link) async {
    if (!await showPortfolioDeleteSheet(context, link) || !mounted) return;
    try {
      await ref.read(portfolioActionsProvider).delete(link);
      if (mounted) _toast('portfolio.toast.deleted', link.title);
    } on ApiError catch (e) {
      if (!mounted) return;
      // Changed or removed elsewhere: reload so the list shows the latest.
      if (e.code == PortfolioConstants.codeVersionConflict || e.isNotFound) {
        ref.invalidate(portfolioProvider);
        _toast('portfolio.toast.alreadyGone', link.title, error: true);
        return;
      }
      _toast('portfolio.errors.deleteFailed', link.title, error: true);
    } catch (_) {
      if (mounted) {
        _toast('portfolio.errors.deleteFailed', link.title, error: true);
      }
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final async = ref.watch(portfolioProvider);

    return ScreenScaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: tr('portfolio.add'),
        shape: const CircleBorder(),
        backgroundColor: colors.primary,
        foregroundColor: colors.primaryForeground,
        onPressed: _add,
        child: const Icon(LucideIcons.plus),
      ),
      appBar: AppBar(
        leadingWidth: 96,
        leading: Navigator.of(context).canPop()
            ? TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: colors.primary),
                icon: const Icon(LucideIcons.chevronLeft, size: 20),
                label: Text(tr('portfolio.back')),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('portfolio.title'),
            style: AppTypography.display(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colors.foreground,
            ),
          ),
          Expanded(
            child: async.when(
              skipLoadingOnReload: false,
              loading: _skeleton,
              error: (error, _) => AppEmptyState(
                icon: const Icon(LucideIcons.triangleAlert),
                title: tr('portfolio.errors.loadTitle'),
                description: tr('portfolio.errors.loadDescription'),
                actionText: tr('portfolio.errors.retry'),
                onAction: () => ref.invalidate(portfolioProvider),
              ),
              data: (data) {
                if (data.items.isEmpty) {
                  // No Add button here: the + in the corner already adds.
                  return AppEmptyState(
                    icon: const Icon(LucideIcons.link),
                    title: tr('portfolio.empty.title'),
                    description: tr('portfolio.empty.description'),
                  );
                }
                return RefreshIndicator(
                  color: colors.primary,
                  onRefresh: () => ref.refresh(portfolioProvider.future),
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 16, bottom: 96),
                    itemCount: data.items.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) => index == data.items.length
                        ? _footer(data)
                        : PortfolioCard(
                            link: data.items[index],
                            highlighted: data.items[index].id == _highlightId,
                            onOpenLink: () => _openLink(data.items[index]),
                            onMore: () => _openMenu(data.items[index]),
                          ),
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
