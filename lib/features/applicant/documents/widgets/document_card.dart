import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/ui/app_badge.dart';
import '../../../../components/ui/app_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_typography.dart';
import '../document_formatters.dart';
import '../document_model.dart';

class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.item,
    required this.isBusy,
    required this.onAction,
    this.downloadProgress,
    this.downloadPhase,
  });

  final DocumentDto item;
  final bool isBusy;
  final VoidCallback onAction;
  final double? downloadProgress;
  final String? downloadPhase;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCv = item.type == DocumentType.cv;
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
                  color: isCv ? colors.statusPeachBg : colors.statusInfoBg,
                  borderRadius: AppRadius.inputRadius,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.fileText,
                      size: 18,
                      color: isCv ? colors.primary : colors.statusInfoFg,
                    ),
                    Text(
                      tr(isCv ? 'documents.typeCv' : 'documents.mobile.cl'),
                      style: AppTypography.body(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isCv ? colors.primary : colors.statusInfoFg,
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
                    if (isCv && item.isDefault)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: AppBadge(
                          label: tr('documents.mobile.defaultCv'),
                          tone: BadgeTone.peach,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '${tr(isCv ? 'documents.typeCv' : 'documents.typeCoverLetter')} · ${formatDocumentSize(item.size)} · ${DateFormat('d MMM yyyy', context.locale.toString()).format(item.createdAt.toLocal())}',
                      style: AppTypography.body(
                        fontSize: 13,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('menu_${item.id}'),
                tooltip: tr(
                  'documents.mobile.actions',
                  namedArgs: {'name': item.fileName},
                ),
                icon: const Icon(LucideIcons.ellipsisVertical),
                onPressed: isBusy ? null : onAction,
              ),
            ],
          ),
          if (downloadPhase != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(tr('documents.mobile.download$downloadPhase')),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: downloadProgress,
                    color: colors.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
