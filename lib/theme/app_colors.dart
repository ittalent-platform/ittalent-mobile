import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.border,
    required this.input,
    required this.ring,
    required this.primary,
    required this.primaryForeground,
    required this.candidatePrimary,
    required this.destructive,
    required this.destructiveForeground,
    required this.fgLink,
    required this.statusSuccessBg,
    required this.statusSuccessFg,
    required this.statusSuccessBorder,
    required this.statusWarningBg,
    required this.statusWarningFg,
    required this.statusWarningBorder,
    required this.statusInfoBg,
    required this.statusInfoFg,
    required this.statusInfoBorder,
    required this.statusBlockedBg,
    required this.statusBlockedFg,
    required this.statusBlockedBorder,
    required this.statusPeachBg,
    required this.statusPeachFg,
    required this.statusErrorBg,
    required this.statusErrorFg,
    required this.statusNeutralBg,
    required this.statusNeutralFg,
  });

  // Core Warm Canvas & Ink
  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color border;
  final Color input;
  final Color ring;

  // Brand Primaries (Ember)
  final Color primary;
  final Color primaryForeground;
  final Color candidatePrimary;
  final Color destructive;
  final Color destructiveForeground;
  final Color fgLink;

  // Semantic Status Tint Pairs (DESIGN.md)
  final Color statusSuccessBg;
  final Color statusSuccessFg;
  final Color statusSuccessBorder;

  final Color statusWarningBg;
  final Color statusWarningFg;
  final Color statusWarningBorder;

  final Color statusInfoBg;
  final Color statusInfoFg;
  final Color statusInfoBorder;

  final Color statusBlockedBg;
  final Color statusBlockedFg;
  final Color statusBlockedBorder;

  final Color statusPeachBg;
  final Color statusPeachFg;

  final Color statusErrorBg;
  final Color statusErrorFg;

  final Color statusNeutralBg;
  final Color statusNeutralFg;

  static const light = AppColors(
    background: Color(0xFFFAFAF8),
    foreground: Color(0xFF19191C),
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF19191C),
    secondary: Color(0xFFF6F5F1),
    secondaryForeground: Color(0xFF19191C),
    muted: Color(0xFFF6F5F1),
    mutedForeground: Color(0xFF64646B),
    border: Color(0xFFE6E4DF),
    input: Color(0xFFDEDCD6),
    ring: Color(0xFFF2470C),
    primary: Color(0xFFF2470C),
    primaryForeground: Color(0xFFFFFFFF),
    candidatePrimary: Color(0xFFD73C03),
    destructive: Color(0xFFB42318),
    destructiveForeground: Color(0xFFFFFFFF),
    fgLink: Color(0xFFB33305),
    statusSuccessBg: Color(0xFFF0F9F4),
    statusSuccessFg: Color(0xFF2E7D32),
    statusSuccessBorder: Color(0xFFBCE0CC),
    statusWarningBg: Color(0xFFFEF9EE),
    statusWarningFg: Color(0xFFB76E00),
    statusWarningBorder: Color(0xFFF0D9AD),
    statusInfoBg: Color(0xFFF0F4FF),
    statusInfoFg: Color(0xFF1D4ED8),
    statusInfoBorder: Color(0xFFBFDBFE),
    statusBlockedBg: Color(0xFFFBF4FE),
    statusBlockedFg: Color(0xFF7E22CE),
    statusBlockedBorder: Color(0xFFD9CCF3),
    statusPeachBg: Color(0xFFFEF2ED),
    statusPeachFg: Color(0xFFC2410C),
    statusErrorBg: Color(0xFFFBE9E7),
    statusErrorFg: Color(0xFFB42318),
    statusNeutralBg: Color(0xFFF4F4F5),
    statusNeutralFg: Color(0xFF52525B),
  );

  /// The opposite palette, for surfaces like toasts that must stand out from
  /// the screen: dark on the light theme, light on the dark theme.
  static AppColors inverseOf(Brightness brightness) =>
      brightness == Brightness.light ? dark : light;

  static const dark = AppColors(
    background: Color(0xFF121214),
    foreground: Color(0xFFF5F5F5),
    card: Color(0xFF1A1A1D),
    cardForeground: Color(0xFFF5F5F5),
    secondary: Color(0xFF232328),
    secondaryForeground: Color(0xFFF5F5F5),
    muted: Color(0xFF232328),
    mutedForeground: Color(0xFFA1A1AA),
    border: Color(0xFF2E2E34),
    input: Color(0xFF383840),
    ring: Color(0xFFF2470C),
    primary: Color(0xFFF2470C),
    primaryForeground: Color(0xFFFFFFFF),
    candidatePrimary: Color(0xFFF2470C),
    destructive: Color(0xFFEF4444),
    destructiveForeground: Color(0xFFFFFFFF),
    fgLink: Color(0xFFF97316),
    statusSuccessBg: Color(0xFF14291B),
    statusSuccessFg: Color(0xFF4ADE80),
    statusSuccessBorder: Color(0xFF1C4527),
    statusWarningBg: Color(0xFF2C220E),
    statusWarningFg: Color(0xFFFBBF24),
    statusWarningBorder: Color(0xFF4D3B17),
    statusInfoBg: Color(0xFF132242),
    statusInfoFg: Color(0xFF60A5FA),
    statusInfoBorder: Color(0xFF1D3567),
    statusBlockedBg: Color(0xFF261537),
    statusBlockedFg: Color(0xFFC084FC),
    statusBlockedBorder: Color(0xFF40225E),
    statusPeachBg: Color(0xFF2C1910),
    statusPeachFg: Color(0xFFFB923C),
    statusErrorBg: Color(0xFF2D1515),
    statusErrorFg: Color(0xFFF87171),
    statusNeutralBg: Color(0xFF27272A),
    statusNeutralFg: Color(0xFFA1A1AA),
  );

  @override
  ThemeExtension<AppColors> copyWith({
    Color? background,
    Color? foreground,
    Color? card,
    Color? cardForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? muted,
    Color? mutedForeground,
    Color? border,
    Color? input,
    Color? ring,
    Color? primary,
    Color? primaryForeground,
    Color? candidatePrimary,
    Color? destructive,
    Color? destructiveForeground,
    Color? fgLink,
    Color? statusSuccessBg,
    Color? statusSuccessFg,
    Color? statusSuccessBorder,
    Color? statusWarningBg,
    Color? statusWarningFg,
    Color? statusWarningBorder,
    Color? statusInfoBg,
    Color? statusInfoFg,
    Color? statusInfoBorder,
    Color? statusBlockedBg,
    Color? statusBlockedFg,
    Color? statusBlockedBorder,
    Color? statusPeachBg,
    Color? statusPeachFg,
    Color? statusErrorBg,
    Color? statusErrorFg,
    Color? statusNeutralBg,
    Color? statusNeutralFg,
  }) {
    return AppColors(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      cardForeground: cardForeground ?? this.cardForeground,
      secondary: secondary ?? this.secondary,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      border: border ?? this.border,
      input: input ?? this.input,
      ring: ring ?? this.ring,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      candidatePrimary: candidatePrimary ?? this.candidatePrimary,
      destructive: destructive ?? this.destructive,
      destructiveForeground:
          destructiveForeground ?? this.destructiveForeground,
      fgLink: fgLink ?? this.fgLink,
      statusSuccessBg: statusSuccessBg ?? this.statusSuccessBg,
      statusSuccessFg: statusSuccessFg ?? this.statusSuccessFg,
      statusSuccessBorder: statusSuccessBorder ?? this.statusSuccessBorder,
      statusWarningBg: statusWarningBg ?? this.statusWarningBg,
      statusWarningFg: statusWarningFg ?? this.statusWarningFg,
      statusWarningBorder: statusWarningBorder ?? this.statusWarningBorder,
      statusInfoBg: statusInfoBg ?? this.statusInfoBg,
      statusInfoFg: statusInfoFg ?? this.statusInfoFg,
      statusInfoBorder: statusInfoBorder ?? this.statusInfoBorder,
      statusBlockedBg: statusBlockedBg ?? this.statusBlockedBg,
      statusBlockedFg: statusBlockedFg ?? this.statusBlockedFg,
      statusBlockedBorder: statusBlockedBorder ?? this.statusBlockedBorder,
      statusPeachBg: statusPeachBg ?? this.statusPeachBg,
      statusPeachFg: statusPeachFg ?? this.statusPeachFg,
      statusErrorBg: statusErrorBg ?? this.statusErrorBg,
      statusErrorFg: statusErrorFg ?? this.statusErrorFg,
      statusNeutralBg: statusNeutralBg ?? this.statusNeutralBg,
      statusNeutralFg: statusNeutralFg ?? this.statusNeutralFg,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(
    covariant ThemeExtension<AppColors>? other,
    double t,
  ) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardForeground: Color.lerp(cardForeground, other.cardForeground, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryForeground: Color.lerp(
        secondaryForeground,
        other.secondaryForeground,
        t,
      )!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      border: Color.lerp(border, other.border, t)!,
      input: Color.lerp(input, other.input, t)!,
      ring: Color.lerp(ring, other.ring, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground: Color.lerp(
        primaryForeground,
        other.primaryForeground,
        t,
      )!,
      candidatePrimary: Color.lerp(
        candidatePrimary,
        other.candidatePrimary,
        t,
      )!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      destructiveForeground: Color.lerp(
        destructiveForeground,
        other.destructiveForeground,
        t,
      )!,
      fgLink: Color.lerp(fgLink, other.fgLink, t)!,
      statusSuccessBg: Color.lerp(statusSuccessBg, other.statusSuccessBg, t)!,
      statusSuccessFg: Color.lerp(statusSuccessFg, other.statusSuccessFg, t)!,
      statusSuccessBorder: Color.lerp(
        statusSuccessBorder,
        other.statusSuccessBorder,
        t,
      )!,
      statusWarningBg: Color.lerp(statusWarningBg, other.statusWarningBg, t)!,
      statusWarningFg: Color.lerp(statusWarningFg, other.statusWarningFg, t)!,
      statusWarningBorder: Color.lerp(
        statusWarningBorder,
        other.statusWarningBorder,
        t,
      )!,
      statusInfoBg: Color.lerp(statusInfoBg, other.statusInfoBg, t)!,
      statusInfoFg: Color.lerp(statusInfoFg, other.statusInfoFg, t)!,
      statusInfoBorder: Color.lerp(
        statusInfoBorder,
        other.statusInfoBorder,
        t,
      )!,
      statusBlockedBg: Color.lerp(statusBlockedBg, other.statusBlockedBg, t)!,
      statusBlockedFg: Color.lerp(statusBlockedFg, other.statusBlockedFg, t)!,
      statusBlockedBorder: Color.lerp(
        statusBlockedBorder,
        other.statusBlockedBorder,
        t,
      )!,
      statusPeachBg: Color.lerp(statusPeachBg, other.statusPeachBg, t)!,
      statusPeachFg: Color.lerp(statusPeachFg, other.statusPeachFg, t)!,
      statusErrorBg: Color.lerp(statusErrorBg, other.statusErrorBg, t)!,
      statusErrorFg: Color.lerp(statusErrorFg, other.statusErrorFg, t)!,
      statusNeutralBg: Color.lerp(statusNeutralBg, other.statusNeutralBg, t)!,
      statusNeutralFg: Color.lerp(statusNeutralFg, other.statusNeutralFg, t)!,
    );
  }
}

extension AppColorsExtension on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
