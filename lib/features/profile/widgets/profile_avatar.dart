import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.url,
    this.size = 64,
    this.onTap,
  });

  final String name;
  final String? url;
  final double size;
  final VoidCallback? onTap;

  String get _initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join()
      .toUpperCase();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.statusPeachBg,
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: url?.isNotEmpty == true
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(colors),
            )
          : _fallback(colors),
    );
    return onTap == null
        ? avatar
        : Semantics(
            button: true,
            label: tr('profile.avatarTitle'),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: avatar,
            ),
          );
  }

  Widget _fallback(AppColors colors) => Text(
    _initials.isEmpty ? '?' : _initials,
    style: AppTypography.display(
      fontSize: size * .35,
      fontWeight: FontWeight.w600,
      color: colors.statusPeachFg,
    ),
  );
}
