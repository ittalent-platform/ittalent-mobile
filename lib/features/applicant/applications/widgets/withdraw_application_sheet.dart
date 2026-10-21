import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../api/api_error.dart';
import '../../../../components/ui/app_button.dart';
import '../../../../components/ui/app_input.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../applications_constants.dart';
import '../applications_providers.dart';

/// Confirmation with an optional reason (UC-S3-MYAPP-04). Pops `true` once the
/// application is withdrawn, or when the company already moved it (conflict).
class WithdrawApplicationSheet extends ConsumerStatefulWidget {
  const WithdrawApplicationSheet({
    super.key,
    required this.applicationId,
    required this.expectedVersion,
  });

  final String applicationId;
  final int expectedVersion;

  @override
  ConsumerState<WithdrawApplicationSheet> createState() =>
      _WithdrawApplicationSheetState();
}

class _WithdrawApplicationSheetState
    extends ConsumerState<WithdrawApplicationSheet> {
  final _reason = TextEditingController();
  bool _submitting = false;
  String? _reasonError;
  String? _failure;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  // E3: optional, but when entered it must be 5-500 characters after trimming.
  String? _validate() {
    final length = _reason.text.trim().length;
    if (length == 0) return null;
    if (length < ApplicationConstants.reasonMinLength ||
        length > ApplicationConstants.reasonMaxLength) {
      return tr(
        'applications.errors.reasonLength',
        namedArgs: {
          'min': '${ApplicationConstants.reasonMinLength}',
          'max': '${ApplicationConstants.reasonMaxLength}',
        },
      );
    }
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    setState(() {
      _reasonError = error;
      _failure = null;
    });
    if (error != null) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(applicationActionsProvider)
          .withdraw(
            id: widget.applicationId,
            expectedVersion: widget.expectedVersion,
            reason: _reason.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiError catch (e) {
      if (!mounted) return;
      if (e.code == ApplicationConstants.conflictCode) {
        // E2: the company moved it first; reload so the screen shows the truth.
        ref.invalidate(applicationDetailProvider(widget.applicationId));
        ref.invalidate(myApplicationsProvider);
        Navigator.of(context).pop(false);
        return;
      }
      setState(() {
        _submitting = false;
        _failure = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _failure = tr('applications.withdrawFailed');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('applications.withdrawTitle'),
              style: AppTypography.display(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('applications.withdrawDescriptionOne'),
              style: AppTypography.body(
                fontSize: 14,
                color: colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            AppInput(
              controller: _reason,
              label: tr('applications.reasonOptional'),
              hintText: tr('applications.reasonPlaceholder'),
              helperText: tr(
                'applications.reasonHint',
                namedArgs: {'max': '${ApplicationConstants.reasonMaxLength}'},
              ),
              errorText: _reasonError,
              maxLines: 3,
            ),
            if (_failure != null) ...[
              const SizedBox(height: 12),
              Text(
                _failure!,
                style: AppTypography.body(
                  fontSize: 13,
                  color: colors.destructive,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: tr('applications.keepApplication'),
                    variant: AppButtonVariant.outline,
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: tr('applications.withdraw'),
                    variant: AppButtonVariant.destructive,
                    isLoading: _submitting,
                    onPressed: _submitting ? null : _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
