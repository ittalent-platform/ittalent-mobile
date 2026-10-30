import 'dart:math';

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
import '../portfolio_constants.dart';
import '../portfolio_providers.dart';

/// Field-level problems of the form; a null entry means the field is fine.
class PortfolioFormErrors {
  const PortfolioFormErrors({this.title, this.url});

  final String? title;
  final String? url;

  int get count => [title, url].where((e) => e != null).length;
  bool get any => count > 0;
}

PortfolioFormErrors validatePortfolio({
  required String title,
  required String url,
}) {
  final uri = Uri.tryParse(url.trim());
  final host = uri?.host.toLowerCase() ?? '';
  final urlOk =
      uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      (host.contains('.') || host.contains(':')) &&
      uri.userInfo.isEmpty &&
      host != 'localhost' &&
      !host.endsWith('.localhost') &&
      !host.endsWith('.local') &&
      !host.endsWith('.internal') &&
      !_isPrivateIpv4(host) &&
      !_isPrivateIpv6(host) &&
      url.trim().length <= PortfolioConstants.urlMaxLength;
  final titleOk =
      title.trim().isNotEmpty &&
      title.trim().length <= PortfolioConstants.titleMaxLength;
  return PortfolioFormErrors(
    title: titleOk ? null : tr('portfolio.form.errors.title'),
    url: urlOk ? null : tr('portfolio.form.errors.url'),
  );
}

bool _isPrivateIpv4(String host) {
  final parts = host.split('.');
  if (parts.length != 4) return false;
  final octets = parts.map(int.tryParse).toList();
  if (octets.any((octet) => octet == null || octet < 0 || octet > 255)) {
    return false;
  }
  final first = octets[0]!;
  final second = octets[1]!;
  return first == 0 ||
      first == 10 ||
      first == 127 ||
      (first == 169 && second == 254) ||
      (first == 100 && second >= 64 && second <= 127) ||
      (first == 172 && second >= 16 && second <= 31) ||
      (first == 192 && second == 168) ||
      (first == 192 && second == 0) ||
      (first == 198 && second >= 18 && second <= 19) ||
      first >= 224;
}

bool _isPrivateIpv6(String host) {
  final address = host.replaceAll(RegExp(r'^\[|\]$'), '').toLowerCase();
  return address == '::' ||
      address == '::1' ||
      address.startsWith('fc') ||
      address.startsWith('fd') ||
      RegExp(r'^fe[89ab]').hasMatch(address) ||
      address.startsWith('ff') ||
      address.startsWith('::ffff:');
}

/// A new idempotency key; kept for the lifetime of the form so a retry cannot duplicate.
String newPortfolioIdempotencyKey() {
  final random = Random.secure();
  return List.generate(
    PortfolioConstants.idempotencyKeyBytes,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

/// Full-screen page to add a portfolio link. Pops the saved link once created.
class PortfolioFormPage extends ConsumerStatefulWidget {
  const PortfolioFormPage({super.key, this.existing});

  final PortfolioLink? existing;

  static Future<PortfolioLink?> open(
    BuildContext context, {
    PortfolioLink? existing,
  }) => Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PortfolioFormPage(existing: existing),
    ),
  );

  @override
  ConsumerState<PortfolioFormPage> createState() => _PortfolioFormPageState();
}

class _PortfolioFormPageState extends ConsumerState<PortfolioFormPage> {
  final _title = TextEditingController();
  final _url = TextEditingController();
  final _description = TextEditingController();
  final String _idempotencyKey = newPortfolioIdempotencyKey();
  PortfolioFormErrors _errors = const PortfolioFormErrors();
  bool _saving = false;
  String? _failure;
  bool _unavailable = false;
  bool _conflict = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _title.text = existing.title;
      _url.text = existing.url;
      _description.text = existing.description ?? '';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final url = _url.text.trim();
    final description = _description.text.trim();
    final errors = validatePortfolio(title: title, url: url);
    final descriptionTooLong =
        description.length > PortfolioConstants.descriptionMaxLength;
    setState(() {
      _errors = errors;
      _failure = descriptionTooLong
          ? tr('portfolio.form.errors.saveFailed')
          : null;
    });
    if (errors.any || descriptionTooLong) return;

    setState(() => _saving = true);
    try {
      final existing = widget.existing;
      final link = existing == null
          ? await ref
                .read(portfolioActionsProvider)
                .create(
                  idempotencyKey: _idempotencyKey,
                  title: title,
                  url: url,
                  description: description.isEmpty ? null : description,
                )
          : await _update(existing, title, url, description);
      if (mounted) Navigator.of(context).pop(link);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (e.code == PortfolioConstants.codeDuplicateUrl) {
          _errors = PortfolioFormErrors(
            url: tr('portfolio.form.errors.duplicate'),
          );
        } else if (_editing &&
            e.code == PortfolioConstants.codeVersionConflict) {
          _conflict = true;
          _failure = tr('portfolio.form.errors.conflict');
        } else if (_editing && e.isNotFound) {
          _unavailable = true;
          _failure = tr('portfolio.form.errors.unavailable');
        } else {
          _failure = tr('portfolio.form.errors.saveFailed');
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _failure = tr('portfolio.form.errors.saveFailed');
      });
    }
  }

  Future<PortfolioLink> _update(
    PortfolioLink existing,
    String title,
    String url,
    String description,
  ) {
    final changes = <String, Object?>{};
    if (title != existing.title) changes['title'] = title;
    if (url != existing.url) changes['url'] = url;
    final nextDescription = description.isEmpty ? null : description;
    if (nextDescription != existing.description) {
      changes['description'] = nextDescription;
    }
    if (changes.isEmpty) return Future.value(existing);
    return ref
        .read(portfolioActionsProvider)
        .update(current: existing, changes: changes);
  }

  void _loadLatest() {
    ref.invalidate(portfolioProvider);
    Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
          tr(_editing ? 'portfolio.form.editTitle' : 'portfolio.form.addTitle'),
          style: AppTypography.display(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.foreground,
          ),
        ),
        shape: Border(bottom: BorderSide(color: colors.border)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_editing)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                tr(
                  'portfolio.form.editDescription',
                  namedArgs: {'version': '${widget.existing!.version}'},
                ),
                style: AppTypography.body(
                  fontSize: 13,
                  color: colors.mutedForeground,
                ),
              ),
            ),
          if (_errors.any)
            _callout(
              tr(
                _errors.count == 1
                    ? 'portfolio.form.errors.summary_one'
                    : 'portfolio.form.errors.summary_other',
                namedArgs: {'count': '${_errors.count}'},
              ),
            ),
          if (_failure != null) _callout(_failure!),
          if (_conflict || _unavailable)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppButton(
                text: tr('portfolio.form.loadLatest'),
                variant: AppButtonVariant.outline,
                isFullWidth: true,
                onPressed: _loadLatest,
              ),
            ),
          AppInput(
            controller: _title,
            label: tr('portfolio.form.title'),
            hintText: tr('portfolio.form.titlePlaceholder'),
            isRequired: true,
            errorText: _errors.title,
          ),
          const SizedBox(height: 16),
          AppInput(
            controller: _url,
            label: tr('portfolio.form.url'),
            hintText: 'https://',
            helperText: tr('portfolio.form.urlHint'),
            isRequired: true,
            keyboardType: TextInputType.url,
            errorText: _errors.url,
          ),
          const SizedBox(height: 16),
          AppInput(
            controller: _description,
            label: tr('portfolio.form.description'),
            helperText: tr('portfolio.form.optionalHint'),
            maxLines: 3,
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
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
                    ? 'portfolio.form.saving'
                    : _editing
                    ? 'portfolio.form.save'
                    : 'portfolio.form.add',
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
