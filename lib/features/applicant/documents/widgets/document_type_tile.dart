import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_typography.dart';
import '../document_model.dart';

/// Tinted CV / CL tile used by the list card, the upload sheet and the actions
/// sheet so a document type always looks the same.
class DocumentTypeTile extends StatelessWidget {
  const DocumentTypeTile({super.key, required this.type});

  final DocumentType type;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCv = type == DocumentType.cv;
    final foreground = isCv ? colors.primary : colors.statusInfoFg;
    return Container(
      width: 42,
      height: 52,
      decoration: BoxDecoration(
        color: isCv ? colors.statusPeachBg : colors.statusInfoBg,
        borderRadius: AppRadius.inputRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.fileText, size: 18, color: foreground),
          Text(
            tr(isCv ? 'documents.typeCv' : 'documents.mobile.cl'),
            style: AppTypography.body(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
