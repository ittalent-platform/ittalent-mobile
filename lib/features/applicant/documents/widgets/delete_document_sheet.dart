import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../components/ui/app_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../document_model.dart';

Future<bool> showDeleteDocumentSheet(
  BuildContext context,
  DocumentDto item,
) async {
  return await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: context.colors.card,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr(
                    'documents.deleteTitle',
                    namedArgs: {'name': item.fileName},
                  ),
                  style: AppTypography.display(fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('documents.mobile.deleteLibraryDescription'),
                  style: AppTypography.body(
                    color: sheetContext.colors.mutedForeground,
                  ),
                ),
                if (item.type == DocumentType.cv && item.isDefault) ...[
                  const SizedBox(height: 8),
                  Text(
                    tr('documents.mobile.deleteDefaultDescription'),
                    style: AppTypography.body(
                      color: sheetContext.colors.mutedForeground,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                AppButton(
                  text: tr('documents.confirmDelete'),
                  variant: AppButtonVariant.destructive,
                  size: AppButtonSize.lg,
                  isFullWidth: true,
                  onPressed: () => Navigator.pop(sheetContext, true),
                ),
                const SizedBox(height: 8),
                AppButton(
                  text: tr('documents.mobile.cancel'),
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.lg,
                  isFullWidth: true,
                  onPressed: () => Navigator.pop(sheetContext, false),
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;
}
