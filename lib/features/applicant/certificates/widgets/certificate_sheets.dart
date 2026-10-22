import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/ui/app_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../certificates_providers.dart';

enum CertificateMenuAction { openLink, edit, delete }

Future<T?> _showSheet<T>(BuildContext context, List<Widget> children) =>
    showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.colors.card,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...children,
              const SizedBox(height: 16),
              AppButton(
                text: tr('actions.cancel'),
                variant: AppButtonVariant.secondary,
                isFullWidth: true,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      ),
    );

Widget _title(BuildContext context, String text) => Text(
  text,
  style: AppTypography.display(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: context.colors.foreground,
  ),
);

Widget _muted(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.only(top: 4),
  child: Text(
    text,
    style: AppTypography.body(
      fontSize: 14,
      color: context.colors.mutedForeground,
      height: 1.4,
    ),
  ),
);

/// The ⋯ menu of a certificate: name, "domain · Version n", then [actions].
Future<CertificateMenuAction?> showCertificateMenu(
  BuildContext context,
  CertificateLink item, {
  List<CertificateMenuAction> actions = CertificateMenuAction.values,
}) {
  final colors = context.colors;
  Widget row(CertificateMenuAction action) {
    final destructive = action == CertificateMenuAction.delete;
    final color = destructive ? colors.destructive : colors.foreground;
    final (icon, key) = switch (action) {
      CertificateMenuAction.openLink => (
        LucideIcons.externalLink,
        'certificates.openLink',
      ),
      CertificateMenuAction.edit => (LucideIcons.pencil, 'certificates.edit'),
      CertificateMenuAction.delete => (
        LucideIcons.trash2,
        'certificates.deleteMenu',
      ),
    };
    return Builder(
      builder: (rowContext) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, size: 22, color: color),
        title: Text(
          tr(key),
          style: AppTypography.body(fontSize: 16, color: color),
        ),
        onTap: () => Navigator.of(rowContext).pop(action),
      ),
    );
  }

  return _showSheet<CertificateMenuAction>(context, [
    _title(context, item.name),
    _muted(
      context,
      '${item.domain} · ${tr('certificates.version', namedArgs: {'version': '${item.version}'})}',
    ),
    const SizedBox(height: 8),
    for (final (i, action) in actions.indexed) ...[
      if (i > 0) Divider(height: 1, color: colors.border),
      row(action),
    ],
  ]);
}

/// 409: the certificate changed on another device. True means "Load latest".
Future<bool> showCertificateConflictSheet(BuildContext context) async =>
    await _showSheet<bool>(context, [
      _title(context, tr('certificates.conflict.title')),
      _muted(context, tr('certificates.conflict.description')),
      const SizedBox(height: 16),
      Builder(
        builder: (sheetContext) => AppButton(
          text: tr('certificates.conflict.loadLatest'),
          isFullWidth: true,
          onPressed: () => Navigator.of(sheetContext).pop(true),
        ),
      ),
    ]) ??
    false;
