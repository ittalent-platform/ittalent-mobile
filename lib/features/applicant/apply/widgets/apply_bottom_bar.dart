import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../apply_models.dart';
import 'apply_notice_banner.dart';

/// The bar under the steps: the one button that moves on, and above it the
/// message that says why it did not (or could not).
class ApplyBottomBar extends StatelessWidget {
  const ApplyBottomBar({super.key, required this.button, this.notice});

  final Widget button;
  final ApplyNotice? notice;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final notice = this.notice;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (notice != null) ...[
              ApplyNoticeBanner(notice: notice),
              const SizedBox(height: 10),
            ],
            button,
          ],
        ),
      ),
    );
  }
}
