import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../api/api_error.dart';
import '../../auth/auth_notifier.dart';
import '../../components/common/app_error_state.dart';
import '../../components/common/app_toast.dart';
import '../../components/layout/screen_scaffold.dart';
import '../../components/ui/app_badge.dart';
import '../../components/ui/app_button.dart';
import '../../components/ui/app_card.dart';
import '../../components/ui/app_skeleton.dart';
import '../../config/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'profile_constants.dart';
import 'profile_model.dart';
import 'profile_providers.dart';
import 'widgets/avatar_photo_sheet.dart';
import 'widgets/profile_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return ScreenScaffold(
      appBar: AppBar(
        title: Text(tr('profile.title')),
        actions: [
          if (profile.value?.canMutate == true)
            IconButton(
              key: const Key('profile_edit'),
              onPressed: () => context.push(AppRoutes.editProfile),
              icon: const Icon(LucideIcons.pencil),
              tooltip: tr('profile.edit'),
            ),
        ],
      ),
      body: profile.when(
        loading: _ProfileLoading.new,
        error: (error, _) => _ProfileError(error: error),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.read(profileProvider.notifier).refresh(),
          child: ListView(children: [_ProfileBody(profile: data)]),
        ),
      ),
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('profile_loading'),
    children: const [
      Center(child: AppSkeleton(width: 88, height: 88)),
      SizedBox(height: 16),
      Center(child: AppSkeleton(width: 180, height: 24)),
      SizedBox(height: 8),
      Center(child: AppSkeleton(width: 220)),
      SizedBox(height: 28),
      AppSkeleton(height: 150),
      SizedBox(height: 16),
      AppSkeleton(height: 220),
    ],
  );
}

class _ProfileError extends ConsumerWidget {
  const _ProfileError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = error is ApiError ? error as ApiError : null;
    final key = api?.statusCode == 403
        ? 'profile.restricted'
        : api?.statusCode == 404
        ? 'profile.missing'
        : 'profile.loadError';
    return AppErrorState(
      key: Key('profile_error_${api?.statusCode ?? 'generic'}'),
      title: tr('$key.title'),
      message: tr('$key.message'),
      retryText: tr('actions.retry'),
      onRetry: () => ref.read(profileProvider.notifier).refresh(),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.profile});

  final MyProfile profile;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  bool _resending = false;

  Future<void> _resend() async {
    setState(() => _resending = true);
    final messenger = ScaffoldMessenger.of(context);
    final sent = await ref
        .read(authNotifierProvider.notifier)
        .resendVerificationEmail(widget.profile.email);
    if (mounted) {
      setState(() => _resending = false);
      showAppToast(
        messenger,
        tr(sent ? 'profile.verificationSent' : 'profile.verificationFailed'),
        error: !sent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!profile.emailVerified) ...[
          AppCard(
            key: const Key('profile_verify_banner'),
            backgroundColor: colors.statusWarningBg,
            borderColor: colors.statusWarningBorder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('profile.verifyBanner'),
                  style: AppTypography.body(
                    fontSize: 14,
                    color: colors.statusWarningFg,
                  ),
                ),
                const SizedBox(height: 10),
                AppButton(
                  key: const Key('profile_resend_verification'),
                  text: tr('profile.resendVerification'),
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.outline,
                  isLoading: _resending,
                  onPressed: _resending ? null : _resend,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Center(
          child: Column(
            children: [
              ProfileAvatar(
                key: const Key('profile_avatar'),
                name: profile.displayName,
                url: profile.avatarUrl,
                size: 88,
                onTap: profile.canMutate
                    ? () => AvatarPhotoSheet.show(context, profile)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                profile.displayName,
                style: AppTypography.display(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.email,
                style: AppTypography.body(
                  fontSize: 14,
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _ProfileSection(
          title: tr('profile.personal'),
          children: [
            _TextRow(
              label: tr('profile.fullName'),
              value: _valueOrMissing(profile.fullName),
            ),
            _TextRow(
              label: tr('profile.phone'),
              value: _valueOrMissing(profile.phone),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ProfileSection(
          title: tr('profile.account'),
          children: [
            _TextRow(label: tr('profile.email'), value: profile.email),
            _BadgeRow(
              label: tr('profile.emailVerification'),
              badge: AppBadge(
                label: tr(
                  profile.emailVerified
                      ? 'profile.verified'
                      : 'profile.notVerified',
                ),
                tone: profile.emailVerified
                    ? BadgeTone.success
                    : BadgeTone.warning,
              ),
            ),
            _BadgeRow(
              label: tr('profile.role'),
              badge: AppBadge(
                label: tr(profileRoleTranslationKey(profile.role)),
              ),
            ),
            _BadgeRow(
              label: tr('profile.status'),
              badge: AppBadge(
                label: tr(profileStatusTranslationKey(profile.status)),
                tone: _badgeTone(profileStatusTone(profile.status)),
              ),
            ),
            if (profile.enterpriseName?.trim().isNotEmpty == true)
              _TextRow(
                label: tr('profile.company'),
                value: profile.enterpriseName!.trim(),
              ),
          ],
        ),
      ],
    );
  }

  String _valueOrMissing(String? value) => value?.trim().isNotEmpty == true
      ? value!.trim()
      : tr('profile.notProvided');
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.body(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );
}

class _TextRow extends StatelessWidget {
  const _TextRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => _ProfileRow(
    label: label,
    value: Text(
      value,
      textAlign: TextAlign.end,
      style: AppTypography.body(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: context.colors.foreground,
      ),
    ),
  );
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.label, required this.badge});

  final String label;
  final Widget badge;

  @override
  Widget build(BuildContext context) => _ProfileRow(label: label, value: badge);
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.body(
              fontSize: 14,
              color: context.colors.mutedForeground,
            ),
          ),
        ),
        Flexible(child: value),
      ],
    ),
  );
}

BadgeTone _badgeTone(ProfileStatusTone tone) => switch (tone) {
  ProfileStatusTone.success => BadgeTone.success,
  ProfileStatusTone.warning => BadgeTone.warning,
  ProfileStatusTone.error => BadgeTone.error,
  ProfileStatusTone.neutral => BadgeTone.neutral,
};
