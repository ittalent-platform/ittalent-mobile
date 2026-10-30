import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../components/common/app_toast.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_typography.dart';
import '../companies_format.dart';
import '../companies_models.dart';

/// The About tab: what the company does, its tech stack and the facts about it.
class CompanyAboutTab extends StatelessWidget {
  const CompanyAboutTab({super.key, required this.company});

  final CompanyDetail company;

  static const double gutter = 16;

  Future<void> _openWebsite(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!opened) {
      showAppToast(
        messenger,
        tr(
          'companies.page.linkFailed',
          namedArgs: {'site': CompanyFormat.websiteLabel(uri)},
        ),
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final description = company.description ?? company.summary.shortDescription;
    final website = CompanyFormat.websiteUri(company.website);
    final summary = company.summary;
    final captionStyle = AppTypography.body(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.7,
      color: colors.mutedForeground,
    );

    // A company with one city has no other offices to list.
    final facts = <(String, Widget)>[
      if (summary.industry != null)
        ('companies.page.industry', _FactValue(text: summary.industry!)),
      if (summary.companySize != null)
        (
          'companies.page.size',
          _FactValue(text: CompanyFormat.sizeText(summary.companySize!)),
        ),
      if (company.headquarters != null)
        (
          'companies.page.headquarters',
          _FactValue(text: company.headquarters!),
        ),
      if (summary.cities.length > 1)
        (
          'companies.page.offices',
          _FactValue(text: CompanyFormat.cities(summary.cities)),
        ),
      if (website != null)
        (
          'companies.page.website',
          _FactValue(
            text: CompanyFormat.websiteLabel(website),
            onTap: () => _openWebsite(context, website),
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description != null || company.techStack.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(gutter, 16, gutter, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description != null)
                  Text(
                    description,
                    style: AppTypography.body(
                      fontSize: 15,
                      height: 1.6,
                      color: colors.foreground,
                    ),
                  ),
                if (company.techStack.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    tr('companies.page.techStack').toUpperCase(),
                    style: captionStyle,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tech in company.techStack)
                        _TechChip(label: tech),
                    ],
                  ),
                ],
              ],
            ),
          ),
        if (facts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(gutter, 14, gutter, 8),
            child: Text(
              tr('companies.page.facts').toUpperCase(),
              style: captionStyle,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: gutter),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: AppRadius.cardRadius,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < facts.length; i++)
                  _Fact(
                    label: tr(facts[i].$1),
                    last: i == facts.length - 1,
                    child: facts[i].$2,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: gutter),
      ],
    );
  }
}

class _TechChip extends StatelessWidget {
  const _TechChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: AppTypography.body(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: colors.mutedForeground,
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.child, required this.last});

  final String label;
  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.body(
              fontSize: 13,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 3),
          child,
        ],
      ),
    );
  }
}

class _FactValue extends StatelessWidget {
  const _FactValue({required this.text, this.onTap});

  final String text;

  /// Set for a value that opens something, like the website.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = onTap == null
        ? AppTypography.body(
            fontSize: 15.5,
            height: 1.45,
            color: colors.foreground,
          )
        : AppTypography.body(
            fontSize: 15.5,
            height: 1.45,
            fontWeight: FontWeight.w600,
            color: colors.fgLink,
          );
    final value = Text(text, style: style);
    return onTap == null
        ? value
        : InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: value,
            ),
          );
  }
}
