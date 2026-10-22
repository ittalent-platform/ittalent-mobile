import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../api/api_error.dart';
import '../../../../components/ui/app_button.dart';
import '../../../../components/ui/app_input.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_typography.dart';
import '../applications_constants.dart';
import '../applications_providers.dart';

/// Confirmation with an optional reason (UC-S3-MYAPP-04). Pops `true` once the
/// application is withdrawn. When the status changed meanwhile it stays open
/// and says why, with the screen reloaded behind it.
class WithdrawApplicationSheet extends ConsumerStatefulWidget {
  const WithdrawApplicationSheet({
    super.key,
    required this.applicationId,
    required this.companyName,
    required this.expectedVersion,
  });

  final String applicationId;
  final String companyName;
  final int expectedVersion;

  @override
  ConsumerState<WithdrawApplicationSheet> createState() =>
      _WithdrawApplicationSheetState();
}

class _WithdrawApplicationSheetState
    extends ConsumerState<WithdrawApplicationSheet> {
  final _reason = TextEditingController();
  late int _version = widget.expectedVersion;
  bool _submitting = false;
  bool _decided = false;
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
            expectedVersion: _version,
            reason: _reason.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiError catch (e) {
      // E2: 409 (moved meanwhile) or 400 (no longer withdrawable): reload, then
      // explain from the fresh status instead of retrying blindly.
      final changed =
          e.isConflict ||
          e.statusCode == ApplicationConstants.notAllowedStatus ||
          e.code == ApplicationConstants.conflictCode;
      var failure = e.message;
      var decided = false;
      if (changed) {
        ref.invalidate(myApplicationsProvider);
        ref.invalidate(applicationDetailProvider(widget.applicationId));
        try {
          final fresh = await ref.read(
            applicationDetailProvider(widget.applicationId).future,
          );
          _version = fresh.version;
          decided = !fresh.summary.canWithdraw;
          failure = decided
              ? tr(
                  'applications.alreadyDecided',
                  namedArgs: {
                    'status': tr(
                      ApplicationConstants.statusKey(fresh.summary.status),
                    ).toLowerCase(),
                  },
                )
              : e.statusCode == ApplicationConstants.notAllowedStatus
              ? e.message
              : tr('applications.withdrawConflict');
        } catch (_) {
          failure = tr('applications.withdrawConflict');
        }
      }
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _decided = decided;
        _failure = failure;
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
        16,
        0,
        16,
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
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                'applications.withdrawSheetBody',
                namedArgs: {'company': widget.companyName},
              ),
              style: AppTypography.body(
                fontSize: 14,
                color: colors.mutedForeground,
                height: 1.4,
              ),
            ),
            if (!_decided) ...[
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
            ],
            if (_failure != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.statusErrorBg,
                  borderRadius: AppRadius.inputRadius,
                  border: Border.all(
                    color: colors.destructive.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.triangleAlert,
                      size: 16,
                      color: colors.statusErrorFg,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _failure!,
                        style: AppTypography.body(
                          fontSize: 13,
                          color: colors.statusErrorFg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (!_decided) ...[
              AppButton(
                text: tr('applications.withdraw'),
                variant: AppButtonVariant.destructive,
                isFullWidth: true,
                isLoading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
              const SizedBox(height: 8),
            ],
            AppButton(
              text: tr('applications.keepApplication'),
              variant: AppButtonVariant.secondary,
              isFullWidth: true,
              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
