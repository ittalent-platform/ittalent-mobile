import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../components/ui/app_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../apply_models.dart';
import 'apply_style.dart';

/// Step 2: the documents that go with the application, and "Change" to go
/// back to step 1 and pick others.
class ApplyDocumentsCard extends StatelessWidget {
  const ApplyDocumentsCard({
    super.key,
    required this.cv,
    required this.onChange,
    this.coverLetter,
  });

  final ApplyDocument cv;
  final ApplyDocument? coverLetter;
  final VoidCallback onChange;

  static const double rowHeight = 40;

  Widget _row(BuildContext context, String tag, String name) {
    final colors = context.colors;
    return Container(
      height: rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: colors.brandTint,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              tag,
              style: AppTypography.body(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: colors.fgLink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(fontSize: 14, color: colors.foreground),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final letter = coverLetter;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr('apply.documents').toUpperCase(),
                  style: AppTypography.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.78,
                    color: colors.mutedForeground,
                  ),
                ),
              ),
              InkWell(
                onTap: onChange,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Text(
                    tr('apply.change'),
                    style: AppTypography.body(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: colors.fgLink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _row(context, tr('apply.tagCv'), cv.fileName),
          const SizedBox(height: 8),
          if (letter == null)
            Text(
              tr('apply.noCoverLetter'),
              style: AppTypography.body(
                fontSize: 13.5,
                color: colors.mutedForeground,
              ),
            )
          else
            _row(context, tr('apply.tagCoverLetter'), letter.fileName),
        ],
      ),
    );
  }
}
