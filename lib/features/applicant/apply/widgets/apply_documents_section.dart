import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/ui/app_skeleton.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../apply_models.dart';
import 'apply_notice_banner.dart';
import 'apply_option_card.dart';
import 'apply_pill.dart';
import 'apply_upload_card.dart';

/// Step 1: one list of the applicant's documents of a kind (their CVs, or
/// their cover letters) with a way to upload one more. A cover letter is
/// optional, so its list starts with "No cover letter".
class ApplyDocumentsSection extends StatelessWidget {
  const ApplyDocumentsSection({
    super.key,
    required this.title,
    required this.documents,
    required this.selectedId,
    required this.onSelect,
    required this.uploadTitle,
    required this.onUpload,
    required this.onRetry,
    required this.defaultLabel,
    this.isRequired = false,
    this.noneTitle,
    this.uploading = false,
  });

  final String title;
  final AsyncValue<List<ApplyDocument>> documents;

  /// The chosen document; null is "none" for a cover letter.
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final String uploadTitle;
  final VoidCallback onUpload;
  final VoidCallback onRetry;
  final String defaultLabel;
  final bool isRequired;

  /// Title of the "no document" choice; null when one is needed.
  final String? noneTitle;
  final bool uploading;

  static const double gap = 10;

  String _subtitle(BuildContext context, ApplyDocument document) {
    final created = document.createdAt;
    final size = formatFileSize(document.size);
    if (created == null) return size;
    final locale = Localizations.localeOf(context).toString();
    return '$size · ${DateFormat('d MMM yyyy', locale).format(created.toLocal())}';
  }

  Widget _skeleton() => Column(
    children: [
      for (var i = 0; i < 2; i++) ...[
        if (i > 0) const SizedBox(height: gap),
        AppSkeleton(
          height: 68,
          borderRadius: BorderRadius.circular(ApplyOptionCard.radius),
        ),
      ],
    ],
  );

  Widget _failed() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ApplyNoticeBanner(
        notice: const ApplyNotice('apply.errors.loadDocuments'),
      ),
      const SizedBox(height: 4),
      TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(LucideIcons.refreshCw, size: 16),
        label: Text(tr('errorState.retry')),
      ),
    ],
  );

  Widget _list(BuildContext context, List<ApplyDocument> items) {
    final cards = <Widget>[
      if (noneTitle != null)
        ApplyOptionCard(
          selected: selectedId == null,
          title: noneTitle!,
          subtitle: tr('apply.optional'),
          onTap: () => onSelect(null),
        ),
      for (final document in items)
        ApplyOptionCard(
          selected: document.id == selectedId,
          title: document.fileName,
          subtitle: _subtitle(context, document),
          badge: document.isDefault
              ? ApplyPill(label: defaultLabel, icon: LucideIcons.star)
              : null,
          onTap: () => onSelect(document.id),
        ),
      ApplyUploadCard(
        title: uploadTitle,
        hint: tr('apply.uploadHint'),
        uploading: uploading,
        onTap: onUpload,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: gap),
          cards[i],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final heading = AppTypography.body(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: colors.foreground,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text.rich(
            TextSpan(
              text: title,
              style: heading,
              children: [
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: heading.copyWith(color: colors.destructive),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        documents.when(
          skipLoadingOnReload: true,
          loading: _skeleton,
          error: (_, _) => _failed(),
          data: (items) => _list(context, items),
        ),
      ],
    );
  }
}
