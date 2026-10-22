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
  final urlOk =
      uri != null &&
      uri.scheme == 'https' &&
      uri.host.contains('.') &&
      uri.userInfo.isEmpty &&
      url.trim().length <= PortfolioConstants.urlMaxLength;
  final titleOk =
      title.trim().isNotEmpty &&
      title.trim().length <= PortfolioConstants.titleMaxLength;
  return PortfolioFormErrors(
    title: titleOk ? null : tr('portfolio.form.errors.title'),
    url: urlOk ? null : tr('portfolio.form.errors.url'),
  );
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
  const PortfolioFormPage({super.key});

  static Future<PortfolioLink?> open(BuildContext context) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const PortfolioFormPage(),
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
      final link = await ref
          .read(portfolioActionsProvider)
          .create(
            idempotencyKey: _idempotencyKey,
            title: title,
            url: url,
            description: description.isEmpty ? null : description,
          );
      if (mounted) Navigator.of(context).pop(link);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (e.code == PortfolioConstants.codeDuplicateUrl) {
          _errors = PortfolioFormErrors(
            url: tr('portfolio.form.errors.duplicate'),
          );
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
          tr('portfolio.form.addTitle'),
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
                _saving ? 'portfolio.form.saving' : 'portfolio.form.add',
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
