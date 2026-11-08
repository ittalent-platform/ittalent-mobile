import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/ui/app_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../document_formatters.dart';
import '../document_model.dart';
import 'document_type_tile.dart';

enum DocumentMenuAction { view, setDefault, download, delete }

Future<DocumentMenuAction?> showDocumentActionSheet(
  BuildContext context,
  DocumentDto item,
) => showModalBottomSheet<DocumentMenuAction>(
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
          Row(
            children: [
              DocumentTypeTile(type: item.type),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tr(item.type == DocumentType.cv ? 'documents.typeCv' : 'documents.typeCoverLetter')} · ${formatDocumentSize(item.size)} · ${DateFormat('d MMM yyyy', sheetContext.locale.toString()).format(item.createdAt.toLocal())}',
                      style: AppTypography.body(
                        fontSize: 13,
                        color: sheetContext.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ActionRow(
            action: DocumentMenuAction.view,
            icon: LucideIcons.eye,
            label: tr('documents.mobile.view'),
          ),
          if (item.type == DocumentType.cv && !item.isDefault)
            _ActionRow(
              action: DocumentMenuAction.setDefault,
              icon: LucideIcons.star,
              label: tr('documents.mobile.setDefault'),
            ),
          _ActionRow(
            action: DocumentMenuAction.download,
            icon: LucideIcons.download,
            label: tr('documents.mobile.download'),
          ),
          _ActionRow(
            action: DocumentMenuAction.delete,
            icon: LucideIcons.trash2,
            label: tr('documents.mobile.delete'),
            destructive: true,
            last: true,
          ),
          const SizedBox(height: 12),
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.action,
    required this.icon,
    required this.label,
    this.destructive = false,
    this.last = false,
  });

  final DocumentMenuAction action;
  final IconData icon;
  final String label;
  final bool destructive;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? context.colors.destructive
        : context.colors.foreground;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: context.colors.border)),
      ),
      child: ListTile(
        key: Key('documents_action_${action.name}'),
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: AppTypography.body(fontSize: 16, color: color),
        ),
        onTap: () => Navigator.pop(context, action),
      ),
    );
  }
}
