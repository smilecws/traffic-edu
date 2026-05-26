import 'package:flutter/material.dart';

/// 앱 전역 시맨틱 색 (라이트 / 다크). [ThemeData.extensions]에 등록합니다.
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.background,
    required this.surfaceCard,
    required this.surfaceWhite,
    required this.primary,
    required this.primaryDark,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderLight,
    required this.chipBg,
    required this.success,
    required this.successBg,
    required this.danger,
    required this.dangerBg,
    required this.dangerBorder,
    required this.warning,
    required this.warningBg,
    required this.gradientCyan,
    required this.gradientRose,
    required this.gradientEmerald,
    required this.gradientIndigo,
    required this.gradientAmber,
    required this.gradientViolet,
    required this.gradientTeal,
  });

  final Color background;
  final Color surfaceCard;
  final Color surfaceWhite;
  final Color primary;
  final Color primaryDark;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderLight;
  final Color chipBg;
  // 시맨틱 색 — 합격/정답/불합격/오답/경고 등.
  // 화면 코드에서 hex 직접 사용 대신 이 키를 통해 접근한다.
  final Color success;
  final Color successBg;
  final Color danger;
  final Color dangerBg;
  final Color dangerBorder;
  final Color warning;
  final Color warningBg;
  final List<Color> gradientCyan;
  final List<Color> gradientRose;
  final List<Color> gradientEmerald;
  final List<Color> gradientIndigo;
  final List<Color> gradientAmber;
  final List<Color> gradientViolet;
  final List<Color> gradientTeal;

  static const _gradientCyan = [Color(0xFF06B6D4), Color(0xFF2563EB)];
  static const _gradientRose = [Color(0xFFFB7185), Color(0xFFEC4899)];
  static const _gradientEmerald = [Color(0xFF34D399), Color(0xFF14B8A6)];
  static const _gradientIndigo = [Color(0xFF6366F1), Color(0xFF9333EA)];
  static const _gradientAmber = [Color(0xFFFBBF24), Color(0xFFF97316)];
  static const _gradientViolet = [Color(0xFFA78BFA), Color(0xFFA855F7)];
  static const _gradientTeal = [Color(0xFF2DD4BF), Color(0xFF06B6D4)];

  static const light = AppThemeColors(
    background: Color(0xFFF0FDF4),
    surfaceCard: Color(0xFFECFDF5),
    surfaceWhite: Color(0xFFFFFFFF),
    primary: Color(0xFF22C55E),
    primaryDark: Color(0xFF16A34A),
    onPrimary: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF64748B),
    borderLight: Color(0xFFD1FAE5),
    chipBg: Color(0xFFDCFCE7),
    success: Color(0xFF15803D),
    successBg: Color(0xFFDCFCE7),
    danger: Color(0xFFB91C1C),
    dangerBg: Color(0xFFFEE2E2),
    dangerBorder: Color(0xFFFECACA),
    warning: Color(0xFFB45309),
    warningBg: Color(0xFFFEF3C7),
    gradientCyan: _gradientCyan,
    gradientRose: _gradientRose,
    gradientEmerald: _gradientEmerald,
    gradientIndigo: _gradientIndigo,
    gradientAmber: _gradientAmber,
    gradientViolet: _gradientViolet,
    gradientTeal: _gradientTeal,
  );

  static const dark = AppThemeColors(
    background: Color(0xFF0C1210),
    surfaceCard: Color(0xFF142318),
    surfaceWhite: Color(0xFF1A2E22),
    primary: Color(0xFF4ADE80),
    primaryDark: Color(0xFF22C55E),
    onPrimary: Color(0xFF052E16),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    borderLight: Color(0xFF2D4A38),
    chipBg: Color(0xFF166534),
    success: Color(0xFF4ADE80),
    successBg: Color(0xFF14532D),
    danger: Color(0xFFFCA5A5),
    dangerBg: Color(0xFF7F1D1D),
    dangerBorder: Color(0xFF991B1B),
    warning: Color(0xFFFCD34D),
    warningBg: Color(0xFF78350F),
    gradientCyan: _gradientCyan,
    gradientRose: _gradientRose,
    gradientEmerald: _gradientEmerald,
    gradientIndigo: _gradientIndigo,
    gradientAmber: _gradientAmber,
    gradientViolet: _gradientViolet,
    gradientTeal: _gradientTeal,
  );

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? surfaceCard,
    Color? surfaceWhite,
    Color? primary,
    Color? primaryDark,
    Color? onPrimary,
    Color? textPrimary,
    Color? textSecondary,
    Color? borderLight,
    Color? chipBg,
    Color? success,
    Color? successBg,
    Color? danger,
    Color? dangerBg,
    Color? dangerBorder,
    Color? warning,
    Color? warningBg,
    List<Color>? gradientCyan,
    List<Color>? gradientRose,
    List<Color>? gradientEmerald,
    List<Color>? gradientIndigo,
    List<Color>? gradientAmber,
    List<Color>? gradientViolet,
    List<Color>? gradientTeal,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceWhite: surfaceWhite ?? this.surfaceWhite,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      onPrimary: onPrimary ?? this.onPrimary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      borderLight: borderLight ?? this.borderLight,
      chipBg: chipBg ?? this.chipBg,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      danger: danger ?? this.danger,
      dangerBg: dangerBg ?? this.dangerBg,
      dangerBorder: dangerBorder ?? this.dangerBorder,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      gradientCyan: gradientCyan ?? this.gradientCyan,
      gradientRose: gradientRose ?? this.gradientRose,
      gradientEmerald: gradientEmerald ?? this.gradientEmerald,
      gradientIndigo: gradientIndigo ?? this.gradientIndigo,
      gradientAmber: gradientAmber ?? this.gradientAmber,
      gradientViolet: gradientViolet ?? this.gradientViolet,
      gradientTeal: gradientTeal ?? this.gradientTeal,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceWhite: Color.lerp(surfaceWhite, other.surfaceWhite, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      chipBg: Color.lerp(chipBg, other.chipBg, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      dangerBorder: Color.lerp(dangerBorder, other.dangerBorder, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      gradientCyan: _lerpColorList(gradientCyan, other.gradientCyan, t),
      gradientRose: _lerpColorList(gradientRose, other.gradientRose, t),
      gradientEmerald: _lerpColorList(gradientEmerald, other.gradientEmerald, t),
      gradientIndigo: _lerpColorList(gradientIndigo, other.gradientIndigo, t),
      gradientAmber: _lerpColorList(gradientAmber, other.gradientAmber, t),
      gradientViolet: _lerpColorList(gradientViolet, other.gradientViolet, t),
      gradientTeal: _lerpColorList(gradientTeal, other.gradientTeal, t),
    );
  }

  static List<Color> _lerpColorList(List<Color> a, List<Color> b, double t) {
    return [
      Color.lerp(a[0], b[0], t)!,
      Color.lerp(a[1], b[1], t)!,
    ];
  }
}

extension AppThemeColorsContext on BuildContext {
  AppThemeColors get appColors =>
      Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.light;
}
