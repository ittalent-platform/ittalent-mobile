import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../api/api_error.dart';
import '../../../../components/ui/app_button.dart';
import '../../../../components/ui/app_input.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';
import '../portfolio_constants.dart';
import '../portfolio_providers.dart';

/// Field-level problems of the form; a null entry means the field is fine.
class PortfolioFormErrors {
  const PortfolioFormErrors({this.title, this.url});

  final String? title;
  final String? url;

  bool get any => title != null || url != null;
}

PortfolioFormErrors validatePortfolio({
  required String title,
  required String url,
}) {
  final uri = Uri.tryParse(url.trim());
  final urlOk =
      uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
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

/// Add a portfolio link. Pops the saved title once the link is created.
class PortfolioFormSheet extends ConsumerStatefulWidget {
  const PortfolioFormSheet({super.key});

  @override
  ConsumerState<PortfolioFormSheet> createState() => _PortfolioFormSheetState();
}

class _PortfolioFormSheetState extends ConsumerState<PortfolioFormSheet> {
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
      await ref
          .read(portfolioActionsProvider)
          .create(
            idempotencyKey: _idempotencyKey,
            title: title,
            url: url,
            description: description.isEmpty ? null : description,
          );
      if (mounted) Navigator.of(context).pop(title);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (e.code == PortfolioConstants.codeDuplicateUrl) {
          _errors = PortfolioFormErrors(
            url: tr('portfolio.form.errors.duplicate'),
          );
        } else {
          _failure = e.message;
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
              tr('portfolio.form.addTitle'),
              style: AppTypography.display(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr('portfolio.form.addDescription'),
              style: AppTypography.body(
                fontSize: 13,
                color: colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            AppInput(
              controller: _title,
              label: tr('portfolio.form.title'),
              hintText: tr('portfolio.form.titlePlaceholder'),
              isRequired: true,
              errorText: _errors.title,
            ),
            const SizedBox(height: 12),
            AppInput(
              controller: _url,
              label: tr('portfolio.form.url'),
              helperText: tr('portfolio.form.urlHint'),
              isRequired: true,
              keyboardType: TextInputType.url,
              errorText: _errors.url,
            ),
            const SizedBox(height: 12),
            AppInput(
              controller: _description,
              label:
                  '${tr('portfolio.form.description')} (${tr('portfolio.form.optional')})',
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
            AppButton(
              text: tr('portfolio.form.add'),
              isFullWidth: true,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
