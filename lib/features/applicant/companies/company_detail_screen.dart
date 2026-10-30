import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../api/api_error.dart';
import '../../../components/common/app_empty_state.dart';
import '../../../components/common/app_error_state.dart';
import '../../../components/common/company_avatar.dart';
import '../../../components/ui/app_button.dart';
import '../../../components/ui/app_skeleton.dart';
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'companies_constants.dart';
import 'companies_format.dart';
import 'companies_models.dart';
import 'companies_providers.dart';
import 'widgets/company_about_tab.dart';
import 'widgets/company_benefits_tab.dart';
import 'widgets/company_jobs_tab.dart';

/// UC-BENT-02: a company's page, with a cover, its About, Jobs and Benefits
/// tabs, and a button that takes the applicant to its open jobs.
class CompanyDetailScreen extends ConsumerStatefulWidget {
  const CompanyDetailScreen({super.key, required this.companyId});

  final String companyId;

  @override
  ConsumerState<CompanyDetailScreen> createState() =>
      _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends ConsumerState<CompanyDetailScreen> {
  static const double circleSize = 220;
  static const double backButtonSize = 40;

  CompanyTab _tab = CompanyTab.about;

  /// Back to where the applicant came from; a link that opened the page
  /// straight has nowhere to go back to, so it goes to the list.
  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.companies);
    }
  }

  Widget _backButton() {
    final colors = context.colors;
    return Positioned(
      left: 12,
      top: 8,
      child: Semantics(
        button: true,
        label: tr('companies.page.back'),
        child: Material(
          color: colors.card.withValues(alpha: 0.9),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _back,
            child: SizedBox(
              width: backButtonSize,
              height: backButtonSize,
              child: Icon(
                LucideIcons.chevronLeft,
                size: 22,
                color: colors.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The dark banner with the brand circle; the logo reaches up into it.
  Widget _cover(String name, {bool loading = false}) {
    final colors = context.colors;
    const outer = CompanyConstants.logoSize + 2 * CompanyConstants.logoBorder;
    const stackHeight =
        CompanyConstants.coverHeight - CompanyConstants.logoOverlap + outer;
    return SizedBox(
      height: stackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: CompanyConstants.coverHeight,
            child: ClipRect(
              child: ColoredBox(
                color: colors.foreground,
                child: Stack(
                  children: [
                    Positioned(
                      right: -60,
                      top: -40,
                      width: circleSize,
                      height: circleSize,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: CompanyConstants.coverHeight - CompanyConstants.logoOverlap,
            child: Container(
              padding: const EdgeInsets.all(CompanyConstants.logoBorder),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(
                  CompanyConstants.logoSize / 4 + CompanyConstants.logoBorder,
                ),
              ),
              child: loading
                  ? const AppSkeleton(
                      width: CompanyConstants.logoSize,
                      height: CompanyConstants.logoSize,
                    )
                  : CompanyAvatar(
                      name: name,
                      size: CompanyConstants.logoSize,
                      tinted: true,
                    ),
            ),
          ),
          _backButton(),
        ],
      ),
    );
  }

  Widget _skeleton() => SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cover('', loading: true),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(width: 200, height: 24),
              SizedBox(height: 10),
              AppSkeleton(width: 240, height: 14),
              SizedBox(height: 28),
              AppSkeleton(height: 14),
              SizedBox(height: 10),
              AppSkeleton(height: 14),
              SizedBox(height: 10),
              AppSkeleton(width: 180, height: 14),
            ],
          ),
        ),
      ],
    ),
  );

  /// A message with a way back, under the cover's back button.
  Widget _status(Widget message) => Stack(
    children: [
      Positioned.fill(child: message),
      _backButton(),
    ],
  );

  Widget _tabs(CompanyDetail company) {
    final colors = context.colors;
    Widget tab(CompanyTab value, String label) {
      final active = value == _tab;
      return Semantics(
        button: true,
        selected: active,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _tab = value),
          child: Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active ? colors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                label,
                style: AppTypography.body(
                  fontSize: 15,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? colors.foreground : colors.mutedForeground,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      // Three short tabs fit side by side; with a large system font the row
      // scrolls instead of overflowing.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            tab(CompanyTab.about, tr('companies.tabs.about')),
            const SizedBox(width: 22),
            tab(
              CompanyTab.jobs,
              tr(
                'companies.tabs.jobs',
                namedArgs: {'count': '${company.summary.openRoleCount}'},
              ),
            ),
            const SizedBox(width: 22),
            tab(CompanyTab.benefits, tr('companies.tabs.benefits')),
          ],
        ),
      ),
    );
  }

  Widget _tabBody(CompanyDetail company) => switch (_tab) {
    CompanyTab.about => CompanyAboutTab(company: company),
    CompanyTab.jobs => CompanyJobsTab(companyId: company.id, onBrowse: _back),
    CompanyTab.benefits => CompanyBenefitsTab(benefits: company.benefits),
  };

  /// "See 8 open jobs"; a company with none has "Browse companies" instead.
  Widget _bottomBar(CompanyDetail company) {
    final colors = context.colors;
    final open = company.summary.openRoleCount;
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: open > 0
            ? AppButton(
                text: CompanyFormat.countText('companies.page.seeJobs', open),
                isFullWidth: true,
                size: AppButtonSize.lg,
                onPressed: () => setState(() => _tab = CompanyTab.jobs),
              )
            : AppButton(
                text: tr('companies.page.browse'),
                isFullWidth: true,
                size: AppButtonSize.lg,
                variant: AppButtonVariant.outline,
                onPressed: _back,
              ),
      ),
    );
  }

  Widget _page(CompanyDetail company) {
    final colors = context.colors;
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: colors.primary,
            onRefresh: () async {
              ref.invalidate(companyDetailProvider(widget.companyId));
              await ref.read(companyDetailProvider(widget.companyId).future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _cover(company.name),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: AppTypography.display(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CompanyFormat.pageSubtitle(company),
                          style: AppTypography.body(
                            fontSize: 14.5,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _tabs(company),
                  _tabBody(company),
                  // No bottom bar on the Jobs tab: keep the list clear of the
                  // system gesture area.
                  if (_tab == CompanyTab.jobs)
                    SizedBox(height: MediaQuery.paddingOf(context).bottom),
                ],
              ),
            ),
          ),
        ),
        if (_tab != CompanyTab.jobs) _bottomBar(company),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(companyDetailProvider(widget.companyId));

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: detail.when(
          skipLoadingOnReload: true,
          loading: _skeleton,
          error: (error, _) {
            final notAvailable =
                error is ApiError &&
                (error.isNotFound ||
                    error.statusCode == CompanyConstants.statusBadRequest);
            return _status(
              notAvailable
                  ? AppEmptyState(
                      icon: const Icon(LucideIcons.building2),
                      title: tr('companies.notAvailable.title'),
                      description: tr('companies.notAvailable.description'),
                      actionText: tr('companies.notAvailable.back'),
                      onAction: _back,
                    )
                  : AppErrorState(
                      title: tr('companies.page.loadError.title'),
                      message: tr('companies.page.loadError.description'),
                      retryText: tr('errorState.retry'),
                      onRetry: () => ref.invalidate(
                        companyDetailProvider(widget.companyId),
                      ),
                    ),
            );
          },
          data: _page,
        ),
      ),
    );
  }
}
