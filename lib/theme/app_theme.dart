import 'package:flutter/material.dart';

import 'app_theme_colors.dart';

const _fontFamily = 'Pretendard';

/// 앱 전역 라이트 테마. main.dart 와 골든 테스트에서 동일하게 참조합니다.
ThemeData buildLightTheme() {
  const ac = AppThemeColors.light;
  final colorScheme = ColorScheme.light(
    primary: ac.primary,
    onPrimary: ac.onPrimary,
    surface: ac.surfaceWhite,
    onSurface: ac.textPrimary,
    onSurfaceVariant: ac.textSecondary,
    outline: ac.borderLight,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    extensions: const [AppThemeColors.light],
    scaffoldBackgroundColor: ac.background,
    fontFamily: _fontFamily,
    textTheme: ThemeData(brightness: Brightness.light).textTheme.apply(
      fontFamily: _fontFamily,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: ac.surfaceWhite,
      selectedItemColor: ac.textSecondary,
      unselectedItemColor: ac.textSecondary,
      elevation: 8,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: ac.surfaceWhite,
      foregroundColor: ac.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ac.textPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ac.primary,
        foregroundColor: ac.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}

/// 앱 전역 다크 테마.
ThemeData buildDarkTheme() {
  const ac = AppThemeColors.dark;
  final colorScheme = ColorScheme.dark(
    primary: ac.primary,
    onPrimary: ac.onPrimary,
    surface: ac.surfaceWhite,
    onSurface: ac.textPrimary,
    onSurfaceVariant: ac.textSecondary,
    outline: ac.borderLight,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    extensions: const [AppThemeColors.dark],
    scaffoldBackgroundColor: ac.background,
    fontFamily: _fontFamily,
    textTheme: ThemeData(brightness: Brightness.dark).textTheme.apply(
      fontFamily: _fontFamily,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: ac.surfaceWhite,
      selectedItemColor: ac.textSecondary,
      unselectedItemColor: ac.textSecondary,
      elevation: 8,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: ac.surfaceWhite,
      foregroundColor: ac.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ac.textPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ac.primary,
        foregroundColor: ac.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}
