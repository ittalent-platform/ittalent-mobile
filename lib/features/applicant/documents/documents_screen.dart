import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../api/api_error.dart';
import '../../../components/common/app_empty_state.dart';
import '../../../components/common/app_error_state.dart';
import '../../../components/layout/screen_scaffold.dart';
import '../../../components/ui/app_badge.dart';
import '../../../components/ui/app_button.dart';
import '../../../components/ui/app_card.dart';
import '../../../components/ui/app_skeleton.dart';
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_typography.dart';
import 'document_model.dart';
import 'documents_providers.dart';

String documentError(Object error, {String fallback = 'documents.loadError'}) {
  if (error is ApiError) {
    final key = switch (error.statusCode) {
      400 => 'invalid',
      401 => 'unauthorized',
      403 => 'forbidden',
      404 => 'notFound',
      502 => 'storage',
      _ => 'network',
    };
    return tr('documents.mobile.$key');
  }
  return tr(fallback);
}

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});
  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  String _size(int bytes) => bytes >= 1048576
      ? '${(bytes / 1048576).toStringAsFixed(1)} MiB'
      : '${(bytes / 1024).toStringAsFixed(1)} KiB';

  Widget _card(DocumentDto item) {
    final colors = context.colors;
    final cv = item.type == DocumentType.cv;
    return AppCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 52,
                decoration: BoxDecoration(
                  color: cv ? colors.statusPeachBg : colors.statusInfoBg,
                  borderRadius: AppRadius.inputRadius,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.fileText,
                      size: 18,
                      color: cv ? colors.primary : colors.statusInfoFg,
                    ),
                    Text(
                      tr(cv ? 'documents.typeCv' : 'documents.mobile.cl'),
                      style: AppTypography.body(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cv ? colors.primary : colors.statusInfoFg,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${tr(cv ? 'documents.typeCv' : 'documents.typeCoverLetter')} · ${_size(item.size)} · ${DateFormat.yMMMd(context.locale.toString()).format(item.createdAt.toLocal())}',
                      style: AppTypography.body(
                        fontSize: 13,
                        color: colors.mutedForeground,
                      ),
                    ),
                    if (item.isDefault)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: AppBadge(
                          label: tr('documents.default'),
                          tone: BadgeTone.peach,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _content(AsyncValue<DocumentsList> async) => async.when(
    skipLoadingOnReload: false,
    loading: () => Column(
      children: List.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.only(top: 12),
          child: AppCard(
            child: AppSkeleton(height: 64, width: double.infinity),
          ),
        ),
      ),
    ),
    error: (error, _) => Column(
      children: [
        AppErrorState(
          title: tr('documents.loadError'),
          message: documentError(error, fallback: 'documents.loadError'),
        ),
        AppButton(
          size: AppButtonSize.lg,
          text: tr('documents.mobile.retry'),
          onPressed: () => ref.invalidate(documentsProvider),
        ),
      ],
    ),
    data: (data) {
      if (data.result.items.isEmpty) {
        return AppEmptyState(
          icon: const Icon(LucideIcons.files),
          title: tr('documents.emptyTitle'),
          description: tr('documents.emptyHint'),
        );
      }
      return Column(
        children: [
          for (final item in data.result.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _card(item),
            ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(documentsProvider);
    return ScreenScaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: tr('documents.mobile.back'),
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.profile);
            }
          },
        ),
        title: Text(tr('documents.title')),
        actions: [
          IconButton(
            tooltip: tr('documents.mobile.refresh'),
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => ref.invalidate(documentsProvider),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final refreshed = ref.refresh(documentsProvider.future);
                try {
                  await refreshed;
                } catch (_) {
                  /* Provider displays the error. */
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 100),
                children: [_content(async)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
