import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../components/ui/app_button.dart';
import '../../../../components/ui/app_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../document_files.dart';
import '../document_formatters.dart';

class DocumentUploadCard extends StatelessWidget {
  const DocumentUploadCard({
    super.key,
    required this.file,
    required this.uploading,
    required this.progress,
    required this.errorMessage,
    required this.canRetry,
    required this.onRetry,
    required this.onChooseAgain,
    required this.onCancel,
  });

  final SelectedDocument? file;
  final bool uploading;
  final double? progress;
  final String? errorMessage;
  final bool canRetry;
  final VoidCallback onRetry;
  final VoidCallback onChooseAgain;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            file?.name ?? tr('documents.uploadFailedTitle'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body(fontWeight: FontWeight.w600),
          ),
          if (file != null) Text(formatDocumentSize(file!.size)),
          const SizedBox(height: 8),
          if (uploading) ...[
            Text(
              tr(
                'documents.mobile.uploadProgress',
                namedArgs: {
                  'percent': progress == null
                      ? '—'
                      : '${(progress! * 100).round()}',
                },
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              color: context.colors.primary,
            ),
            const SizedBox(height: 12),
            AppButton(
              key: const Key('documents_upload_cancel'),
              size: AppButtonSize.md,
              text: tr('documents.mobile.cancel'),
              variant: AppButtonVariant.outline,
              onPressed: onCancel,
            ),
          ],
          if (errorMessage != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                errorMessage!,
                style: AppTypography.body(color: context.colors.destructive),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canRetry)
                  AppButton(
                    size: AppButtonSize.lg,
                    text: tr('documents.mobile.retry'),
                    onPressed: onRetry,
                  ),
                AppButton(
                  size: AppButtonSize.lg,
                  text: tr('documents.mobile.chooseAgain'),
                  variant: AppButtonVariant.outline,
                  onPressed: onChooseAgain,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
