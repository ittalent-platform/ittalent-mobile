import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../api/api_error.dart';
import '../../../../components/common/app_empty_state.dart';
import '../../../../components/ui/app_button.dart';
import '../../../../components/ui/app_card.dart';
import '../../../../components/ui/app_checkbox.dart';
import '../../../../components/ui/app_input.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_typography.dart';
import '../certificates_constants.dart';
import '../certificates_providers.dart';
import 'certificate_sheets.dart';

/// Field-level problems of the form; a null entry means the field is fine.
class CertificateFormErrors {
  const CertificateFormErrors({this.name, this.url, this.dates});

  final String? name;
  final String? url;
  final String? dates;

  int get count => [name, url, dates].where((e) => e != null).length;
  bool get any => count > 0;
}

/// [requireHttps] is off only for a link that was saved before and is unchanged.
CertificateFormErrors validateCertificate({
  required String name,
  required String url,
  String? issuedDate,
  String? expiryDate,
  bool requireHttps = true,
}) {
  final uri = Uri.tryParse(url.trim());
  final urlOk =
      uri != null &&
      (uri.scheme == 'https' || (!requireHttps && uri.scheme == 'http')) &&
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

/// What the form saved. [suggestFailed]: the certificate was added but switching on
/// "Suggest when I apply" afterwards failed.
class CertificateFormResult {
  const CertificateFormResult(this.link, {this.suggestFailed = false});

  final CertificateLink link;
  final bool suggestFailed;
}

/// Full-screen add (when [existing] is null) or edit page. Pops a [CertificateFormResult]
/// on save, or nothing when closed or reloaded after a conflict.
class CertificateFormPage extends ConsumerStatefulWidget {
  const CertificateFormPage({super.key, this.existing});

  final CertificateLink? existing;

  static Future<CertificateFormResult?> open(
    BuildContext context, [
    CertificateLink? existing,
  ]) => Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CertificateFormPage(existing: existing),
    ),
  );

  @override
  ConsumerState<CertificateFormPage> createState() =>
      _CertificateFormPageState();
}

class _CertificateFormPageState extends ConsumerState<CertificateFormPage> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _url = TextEditingController(text: widget.existing?.url);
  late final _issuer = TextEditingController(text: widget.existing?.issuer);
  late String? _issued = widget.existing?.issuedDate;
  late String? _expiry = widget.existing?.expiryDate;
  late bool _noExpiry =
      widget.existing != null && widget.existing!.expiryDate == null;
  late bool _suggested = widget.existing?.suggested ?? false;
  final String _idempotencyKey = newIdempotencyKey();
  CertificateFormErrors _errors = const CertificateFormErrors();
  bool _saving = false;
  bool _gone = false;
  String? _failure;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    for (final c in [_name, _url, _issuer]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();

  Future<void> _pickDate(String? current, ValueChanged<String> onPicked) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(current ?? '') ?? now,
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year + 30),
    );
    if (picked != null) {
      setState(() => onPicked(picked.toIso8601String().substring(0, 10)));
    }
  }

  Future<void> _save() async {
    final draft = CertificateDraft(
      name: _name.text.trim(),
      url: _url.text.trim(),
      issuer: _nullIfEmpty(_issuer.text),
      issuedDate: _issued,
      expiryDate: _noExpiry ? null : _expiry,
    );
    final errors = validateCertificate(
      name: draft.name,
      url: draft.url,
      issuedDate: draft.issuedDate,
      expiryDate: draft.expiryDate,
      requireHttps: draft.url != widget.existing?.url,
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
      final CertificateFormResult result;
      if (_isEdit) {
        result = CertificateFormResult(
          await actions.update(
            current: widget.existing!,
            draft: draft,
            suggested: _suggested,
          ),
        );
      } else {
        result = await _create(actions, draft);
      }
      if (mounted) Navigator.of(context).pop(result);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (e.code == CertificateConstants.codeVersionConflict) {
        if (await showCertificateConflictSheet(context)) {
          ref.invalidate(certificatesProvider);
          if (mounted) Navigator.of(context).pop();
        }
      } else if (e.isNotFound && _isEdit) {
        ref.invalidate(certificatesProvider);
        setState(() => _gone = true);
      } else if (e.code == CertificateConstants.codeDuplicateUrl) {
        setState(
          () => _errors = CertificateFormErrors(
            url: tr('certificates.form.errors.duplicate'),
          ),
        );
      } else {
        setState(() => _failure = _failureText);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _failure = _failureText;
      });
    }
  }

  String get _failureText => tr(
    _isEdit
        ? 'certificates.form.errors.updateFailed'
        : 'certificates.form.errors.saveFailed',
  );

  // The create API takes no `suggested`, so a switched-on suggestion is a follow-up PATCH.
  Future<CertificateFormResult> _create(
    CertificateActions actions,
    CertificateDraft draft,
  ) async {
    final created = await actions.create(
      idempotencyKey: _idempotencyKey,
      draft: draft,
    );
    if (!_suggested) return CertificateFormResult(created);
    try {
      return CertificateFormResult(
        await actions.update(
          current: created,
          draft: CertificateDraft.of(created),
          suggested: true,
        ),
      );
    } catch (_) {
      return CertificateFormResult(created, suggestFailed: true);
    }
  }

  Widget _callout(String text) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.statusErrorBg,
        borderRadius: AppRadius.inputRadius,
        border: Border.all(color: colors.destructive.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.triangleAlert, size: 18, color: colors.destructive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body(
                fontSize: 14,
                color: colors.statusErrorFg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: AppTypography.body(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: context.colors.foreground,
      ),
    ),
  );

  Widget _dateField({
    required Key key,
    required String label,
    required String? value,
    required ValueChanged<String> onPicked,
    String? error,
  }) {
    final colors = context.colors;
    final borderColor = error != null ? colors.destructive : colors.input;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Material(
          color: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.inputRadius,
            side: BorderSide(color: borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: key,
            onTap: _saving ? null : () => _pickDate(value, onPicked),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value == null
                          ? tr('certificates.form.pickDate')
                          : CertificateConstants.displayDate(value),
                      style: AppTypography.body(
                        fontSize: 14,
                        color: value == null
                            ? colors.mutedForeground
                            : colors.foreground,
                      ),
                    ),
                  ),
                  Icon(
                    LucideIcons.calendar,
                    size: 18,
                    color: colors.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (error != null) _fieldError(error),
      ],
    );
  }

  Widget _fieldError(String text) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(LucideIcons.triangleAlert, size: 14, color: colors.destructive),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body(
                fontSize: 13,
                color: colors.destructive,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final muted = AppTypography.body(
      fontSize: 13,
      color: colors.mutedForeground,
    );
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          tooltip: tr('actions.close'),
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          tr(
            _isEdit
                ? 'certificates.form.editTitle'
                : 'certificates.form.addTitle',
          ),
          style: AppTypography.display(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.foreground,
          ),
        ),
        shape: Border(bottom: BorderSide(color: colors.border)),
      ),
      body: _gone
          ? AppEmptyState(
              icon: const Icon(LucideIcons.award),
              title: tr('certificates.gone.title'),
              description: tr('certificates.gone.description'),
              actionText: tr('certificates.gone.back'),
              onAction: () => Navigator.of(context).pop(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_isEdit)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      tr(
                        'certificates.form.editDescription',
                        namedArgs: {'version': '${widget.existing!.version}'},
                      ),
                      style: muted,
                    ),
                  ),
                if (_errors.any)
                  _callout(
                    tr(
                      _errors.count == 1
                          ? 'certificates.form.errors.summary_one'
                          : 'certificates.form.errors.summary_other',
                      namedArgs: {'count': '${_errors.count}'},
                    ),
                  ),
                if (_failure != null) _callout(_failure!),
                AppInput(
                  controller: _name,
                  label: tr('certificates.form.name'),
                  hintText: tr('certificates.form.namePlaceholder'),
                  isRequired: true,
                  errorText: _errors.name,
                ),
                const SizedBox(height: 16),
                AppInput(
                  controller: _url,
                  label: tr('certificates.form.url'),
                  hintText: 'https://',
                  helperText: tr('certificates.form.urlHint'),
                  isRequired: true,
                  keyboardType: TextInputType.url,
                  errorText: _errors.url,
                ),
                const SizedBox(height: 16),
                AppInput(
                  controller: _issuer,
                  label: tr('certificates.form.issuer'),
                  helperText: tr('certificates.form.optionalHint'),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: tr('certificates.form.validity'),
                          style: AppTypography.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                          children: [
                            TextSpan(
                              text: ' · ${tr('certificates.form.optional')}',
                              style: muted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _dateField(
                        key: const Key('certificate_form_issued'),
                        label: tr('certificates.form.issued'),
                        value: _issued,
                        onPicked: (v) => _issued = v,
                      ),
                      if (!_noExpiry) ...[
                        const SizedBox(height: 12),
                        _dateField(
                          key: const Key('certificate_form_expires'),
                          label: tr('certificates.form.expires'),
                          value: _expiry,
                          onPicked: (v) => _expiry = v,
                          error: _errors.dates,
                        ),
                      ],
                      const SizedBox(height: 12),
                      AppCheckbox(
                        value: _noExpiry,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _noExpiry = v ?? false),
                        child: Text(
                          tr('certificates.form.noExpiry'),
                          style: AppTypography.body(
                            fontSize: 14,
                            color: colors.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('certificates.suggestWhenApply'),
                              style: AppTypography.body(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.foreground,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr('certificates.form.suggestHint'),
                              style: muted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _suggested,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _suggested = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _gone
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: colors.card,
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    12 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: AppButton(
                    text: tr(
                      _saving
                          ? 'certificates.form.saving'
                          : _isEdit
                          ? 'certificates.form.save'
                          : 'certificates.form.add',
                    ),
                    size: AppButtonSize.lg,
                    isFullWidth: true,
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ),
            ),
    );
  }
}
