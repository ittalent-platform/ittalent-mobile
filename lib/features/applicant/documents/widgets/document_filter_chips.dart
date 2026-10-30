import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../document_model.dart';
import '../documents_providers.dart';

class DocumentFilterChips extends StatelessWidget {
  const DocumentFilterChips({
    super.key,
    required this.selectedType,
    required this.counts,
    required this.onSelected,
  });

  final DocumentType? selectedType;
  final DocumentFilterCounts? counts;
  final ValueChanged<DocumentType?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final type in <DocumentType?>[null, ...DocumentType.values])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: Key('filter_${type?.value ?? 'all'}'),
                label: Text(_label(type)),
                selected: selectedType == type,
                showCheckmark: false,
                selectedColor: context.colors.statusPeachBg,
                backgroundColor: context.colors.card,
                side: BorderSide(
                  color: selectedType == type
                      ? context.colors.primary
                      : context.colors.border,
                ),
                shape: const StadiumBorder(),
                labelStyle: AppTypography.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selectedType == type
                      ? context.colors.primary
                      : context.colors.foreground,
                ),
                onSelected: (_) => onSelected(type),
              ),
            ),
        ],
      ),
    );
  }

  String _label(DocumentType? type) {
    final label = tr(
      type == null ? 'documents.mobile.all' : 'documents.tabs.${type.value}',
    );
    return tr(
      'documents.mobile.filterCount',
      namedArgs: {'label': label, 'count': '${counts?.forType(type) ?? '—'}'},
    );
  }
}
