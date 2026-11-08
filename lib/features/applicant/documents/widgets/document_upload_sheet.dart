import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/ui/app_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../document_model.dart';
import 'document_type_tile.dart';

/// "What are you uploading?" — one row per document type, then Cancel.
Future<DocumentType?> showDocumentUploadSheet(BuildContext context) =>
    showModalBottomSheet<DocumentType>(
      context: context,
      backgroundColor: context.colors.card,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('documents.mobile.sheetTitle'),
                style: AppTypography.display(fontSize: 22),
              ),
              const SizedBox(height: 8),
              for (final (index, choice) in DocumentType.values.indexed) ...[
                if (index > 0)
                  Divider(height: 1, color: sheetContext.colors.border),
                _UploadRow(type: choice),
              ],
              const SizedBox(height: 16),
              AppButton(
                text: tr('documents.mobile.cancel'),
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.lg,
                isFullWidth: true,
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );

class _UploadRow extends StatelessWidget {
  const _UploadRow({required this.type});

  final DocumentType type;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      key: Key('pick_${type.value}'),
      onTap: () => Navigator.pop(context, type),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            DocumentTypeTile(type: type),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(
                      type == DocumentType.cv
                          ? 'documents.mobile.uploadCv'
                          : 'documents.mobile.uploadCover',
                    ),
                    style: AppTypography.body(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr('documents.mobile.sheetHint'),
                    style: AppTypography.body(
                      fontSize: 13,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: colors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
