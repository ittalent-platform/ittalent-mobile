import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../auth/auth_notifier.dart';
import '../../../components/ui/app_button.dart';
import '../../../config/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../utils/email_launcher.dart';
import '../widgets/auth_email_hero.dart';
import '../widgets/cooldown_timer_button.dart';

class ResetLinkSentScreen extends ConsumerWidget {
  const ResetLinkSentScreen({
    super.key,
    this.email,
    this.onOpenEmailApp,
    this.initialCooldownSeconds = 60,
  });

  final String? email;
  final VoidCallback? onOpenEmailApp;
  final int initialCooldownSeconds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentEmail = (email != null && email!.isNotEmpty)
        ? email!
        : 'an.nguyen@gmail.com';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: IconButton(
                          icon: Icon(
                            LucideIcons.chevronLeft,
                            size: 24,
                            color: colors.foreground,
                          ),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRoutes.forgotPassword);
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                          child: AuthEmailHero(
                            email: currentEmail,
                            title: 'Check your email',
                            instructionsPrefix: 'If an account uses ',
                            instructionsSuffix:
                                ', we’ve sent a link to reset the password.',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppButton(
                              text: 'Open email app',
                              icon: const Icon(LucideIcons.mail, size: 18),
                              size: AppButtonSize.lg,
                              isFullWidth: true,
                              onPressed:
                                  onOpenEmailApp ??
                                  () => launchEmailApp(
                                    context,
                                    email: currentEmail,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            CooldownTimerButton(
                              initialCooldownSeconds: initialCooldownSeconds,
                              onResend: () async {
                                return ref
                                    .read(authNotifierProvider.notifier)
                                    .forgotPassword(currentEmail);
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        child: Center(
                          child: GestureDetector(
                            onTap: () => context.go(AppRoutes.login),
                            child: Text(
                              'Back to sign in',
                              style: AppTypography.body(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB33305),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
