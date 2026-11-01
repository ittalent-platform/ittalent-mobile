import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/ui/app_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../portfolio_providers.dart';

enum PortfolioMenuAction { openLink, edit, delete }

/// Bottom sheet with a title, a muted line, [children] and a Cancel button.
Future<T?> _showSheet<T>(
  BuildContext context, {
  required String title,
  required String subtitle,
  required List<Widget> Function(BuildContext sheetContext) children,
}) {
  final colors = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: colors.card,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTypography.display(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.body(
                fontSize: 14,
                color: colors.mutedForeground,
                height: 1.4,
              ),
            ),
            ...children(sheetContext),
            const SizedBox(height: 16),
            AppButton(
              text: tr('actions.cancel'),
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.lg,
              isFullWidth: true,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The ⋯ menu of a link: title, "domain · Version n", Open link and Delete….
Future<PortfolioMenuAction?> showPortfolioMenu(
  BuildContext context,
  PortfolioLink link,
) {
  final colors = context.colors;
  return _showSheet<PortfolioMenuAction>(
    context,
    title: link.title,
    subtitle:
        '${link.domain} · ${tr('portfolio.version', namedArgs: {'version': '${link.version}'})}',
    children: (sheetContext) {
      Widget row(PortfolioMenuAction action, IconData icon, String key) {
        final color = action == PortfolioMenuAction.delete
            ? colors.destructive
            : colors.foreground;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, size: 22, color: color),
          title: Text(
            tr(key),
            style: AppTypography.body(fontSize: 16, color: color),
          ),
          onTap: () => Navigator.of(sheetContext).pop(action),
        );
      }

      return [
        const SizedBox(height: 8),
        row(
          PortfolioMenuAction.openLink,
          LucideIcons.externalLink,
          'portfolio.openLink',
        ),
        Divider(height: 1, color: colors.border),
        row(PortfolioMenuAction.edit, LucideIcons.pencil, 'portfolio.edit'),
        Divider(height: 1, color: colors.border),
        row(
          PortfolioMenuAction.delete,
          LucideIcons.trash2,
          'portfolio.deleteMenu',
        ),
      ];
    },
  );
}

/// UC-S4-PORT-03 confirmation. True means delete.
Future<bool> showPortfolioDeleteSheet(
  BuildContext context,
  PortfolioLink link,
) async =>
    await _showSheet<bool>(
      context,
      title: tr('portfolio.delete.title', namedArgs: {'name': link.title}),
      subtitle: tr('portfolio.delete.description'),
      children: (sheetContext) => [
        const SizedBox(height: 16),
        AppButton(
          text: tr('portfolio.delete.confirm'),
          variant: AppButtonVariant.destructive,
          size: AppButtonSize.lg,
          isFullWidth: true,
          onPressed: () => Navigator.of(sheetContext).pop(true),
        ),
      ],
    ) ??
    false;
