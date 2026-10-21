import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../api/api_error.dart';
import '../../../../components/ui/app_button.dart';
import '../../../../components/ui/app_input.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../certificates_constants.dart';
import '../certificates_providers.dart';

/// Field-level problems of the form; a null entry means the field is fine.
class CertificateFormErrors {
  const CertificateFormErrors({this.name, this.url, this.dates});

  final String? name;
  final String? url;
  final String? dates;

  bool get any => name != null || url != null || dates != null;
}

CertificateFormErrors validateCertificate({
  required String name,
  required String url,
  String? issuedDate,
  String? expiryDate,
}) {
  final uri = Uri.tryParse(url.trim());
  final urlOk =
      uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.contains('.') &&
      uri.userInfo.isEmpty &&
      url.trim().length <= CertificateConstants.urlMaxLength;
  final nameOk =
      name.trim().isNotEmpty &&
      name.trim().length <= CertificateConstants.nameMaxLength;
  // YYYY-MM-DD strings sort like dates.
  final datesOk =
      issuedDate == null ||
      expiryDate == null ||
      expiryDate.compareTo(issuedDate) >= 0;
  return CertificateFormErrors(
    name: nameOk ? null : tr('certificates.form.errors.name'),
    url: urlOk ? null : tr('certificates.form.errors.url'),
    dates: datesOk ? null : tr('certificates.form.errors.dates'),
  );
}

/// A new idempotency key; kept for the lifetime of the form so a retry cannot duplicate.
String newIdempotencyKey() {
  final random = Random.secure();
  return List.generate(
    CertificateConstants.idempotencyKeyBytes,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

enum CertificateFormOutcome { added, saved, deleted, conflict }

class CertificateFormResult {
  const CertificateFormResult(this.outcome, this.name);

  final CertificateFormOutcome outcome;
  final String name;
}

/// Add (when [existing] is null) or edit a certificate. Pops a [CertificateFormResult];
/// `conflict` means it changed elsewhere and the list was reloaded.
class CertificateFormSheet extends ConsumerStatefulWidget {
  const CertificateFormSheet({super.key, this.existing});

  final CertificateLink? existing;

  @override
  ConsumerState<CertificateFormSheet> createState() =>
      _CertificateFormSheetState();
}

class _CertificateFormSheetState extends ConsumerState<CertificateFormSheet> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _url = TextEditingController(text: widget.existing?.url);
  late final _issuer = TextEditingController(text: widget.existing?.issuer);
  late final _issued = TextEditingController(text: widget.existing?.issuedDate);
  late final _expiry = TextEditingController(text: widget.existing?.expiryDate);
  late bool _suggested = widget.existing?.suggested ?? false;
  final String _idempotencyKey = newIdempotencyKey();
  CertificateFormErrors _errors = const CertificateFormErrors();
  bool _saving = false;
  String? _failure;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    for (final c in [_name, _url, _issuer, _issued, _expiry]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? now,
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year + 30),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  Future<void> _save() async {
    final draft = CertificateDraft(
      name: _name.text.trim(),
      url: _url.text.trim(),
      issuer: _nullIfEmpty(_issuer.text),
      issuedDate: _nullIfEmpty(_issued.text),
      expiryDate: _nullIfEmpty(_expiry.text),
    );
    final errors = validateCertificate(
      name: draft.name,
      url: draft.url,
      issuedDate: draft.issuedDate,
      expiryDate: draft.expiryDate,
    );
    final issuerTooLong =
        (draft.issuer?.length ?? 0) > CertificateConstants.issuerMaxLength;
    setState(() {
      _errors = errors;
      _failure = issuerTooLong
          ? tr('certificates.form.errors.saveFailed')
          : null;
    });
    if (errors.any || issuerTooLong) return;

    setState(() => _saving = true);
    final actions = ref.read(certificateActionsProvider);
    try {
      if (_isEdit) {
        await actions.update(
          current: widget.existing!,
          draft: draft,
          suggested: _suggested,
        );
      } else {
        await actions.create(idempotencyKey: _idempotencyKey, draft: draft);
      }
      if (mounted) {
        Navigator.of(context).pop(
          CertificateFormResult(
            _isEdit
                ? CertificateFormOutcome.saved
                : CertificateFormOutcome.added,
            draft.name,
          ),
        );
      }
    } on ApiError catch (e) {
      if (!mounted) return;
      if (e.code == CertificateConstants.codeVersionConflict) {
        // Edited or deleted elsewhere: reload so the list shows the latest.
        ref.invalidate(certificatesProvider);
        Navigator.of(
          context,
        ).pop(const CertificateFormResult(CertificateFormOutcome.conflict, ''));
        return;
      }
      setState(() {
        _saving = false;
        if (e.code == CertificateConstants.codeDuplicateUrl) {
          _errors = CertificateFormErrors(
            url: tr('certificates.form.errors.duplicate'),
          );
        } else {
          _failure = e.message;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _failure = tr(
          _isEdit
              ? 'certificates.form.errors.updateFailed'
              : 'certificates.form.errors.saveFailed',
        );
      });
    }
  }

  Future<void> _confirmDelete() async {
    final existing = widget.existing!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('certificates.delete.title')),
        content: Text(
          '${existing.name}\n\n${tr('certificates.delete.description', namedArgs: {'name': existing.name}).replaceAll(RegExp('</?b>'), '')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(tr('certificates.delete.keep')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(tr('certificates.delete.confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _saving = true;
      _failure = null;
    });
    try {
      await ref.read(certificateActionsProvider).delete(existing);
      if (mounted) {
        Navigator.of(context).pop(
          CertificateFormResult(CertificateFormOutcome.deleted, existing.name),
        );
      }
    } on ApiError catch (e) {
      if (!mounted) return;
      if (e.code == CertificateConstants.codeVersionConflict || e.isNotFound) {
        ref.invalidate(certificatesProvider);
        Navigator.of(
          context,
        ).pop(const CertificateFormResult(CertificateFormOutcome.conflict, ''));
        return;
      }
      setState(() {
        _saving = false;
        _failure = tr('certificates.errors.deleteFailed');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _failure = tr('certificates.errors.deleteFailed');
      });
    }
  }

  Widget _dateField(String labelKey, TextEditingController controller) =>
      AppInput(
        controller: controller,
        label: tr(labelKey),
        readOnly: true,
        onTap: () => _pickDate(controller),
        suffixIcon: controller.text.isEmpty
            ? const Icon(LucideIcons.calendar, size: 18)
            : IconButton(
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: () => setState(controller.clear),
              ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final existing = widget.existing;
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
              tr(
                _isEdit
                    ? 'certificates.form.editTitle'
                    : 'certificates.form.addTitle',
              ),
              style: AppTypography.display(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr(
                _isEdit
                    ? 'certificates.form.editDescription'
                    : 'certificates.form.addDescription',
                namedArgs: {'version': '${existing?.version ?? 1}', 'date': ''},
              ),
              style: AppTypography.body(
                fontSize: 13,
                color: colors.mutedForeground,
              ),
            ),
            if (existing != null && existing.sentCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                tr(
                  existing.sentCount == 1
                      ? 'certificates.form.sentNote_one'
                      : 'certificates.form.sentNote_other',
                  namedArgs: {'count': '${existing.sentCount}'},
                ),
                style: AppTypography.body(
                  fontSize: 13,
                  color: colors.mutedForeground,
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppInput(
              controller: _name,
              label: tr('certificates.form.name'),
              hintText: tr('certificates.form.namePlaceholder'),
              isRequired: true,
              errorText: _errors.name,
            ),
            const SizedBox(height: 12),
            AppInput(
              controller: _url,
              label: tr('certificates.form.url'),
              helperText: tr('certificates.form.urlHint'),
              isRequired: true,
              keyboardType: TextInputType.url,
              errorText: _errors.url,
            ),
            const SizedBox(height: 12),
            AppInput(
              controller: _issuer,
              label:
                  '${tr('certificates.form.issuer')} (${tr('certificates.form.optional')})',
            ),
            const SizedBox(height: 12),
            _dateField('certificates.form.issued', _issued),
            const SizedBox(height: 12),
            _dateField('certificates.form.expires', _expiry),
            if (_errors.dates != null) ...[
              const SizedBox(height: 6),
              Text(
                _errors.dates!,
                style: AppTypography.body(
                  fontSize: 13,
                  color: colors.destructive,
                ),
              ),
            ],
            if (_isEdit) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr('certificates.form.suggest')),
                subtitle: Text(tr('certificates.form.suggestHint')),
                value: _suggested,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _suggested = value),
              ),
            ],
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
            AppButton(
              text: tr(
                _isEdit ? 'certificates.form.save' : 'certificates.form.add',
              ),
              isFullWidth: true,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
            if (_isEdit) ...[
              const SizedBox(height: 8),
              AppButton(
                text: tr('certificates.delete.confirm'),
                variant: AppButtonVariant.destructive,
                isFullWidth: true,
                onPressed: _saving ? null : _confirmDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
