import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_theme_colors.dart';

/// 글래스 톤 AppBar. 투명 + BackdropFilter 블러 + 살짝 반투명 흰색 배경.
///
/// 내부 화면(Navigator.push 진입)에서 사용한다. `automaticallyImplyLeading: true`
/// 가 기본이라 뒤로가기 leading 이 자동으로 들어간다. `bottom` 에 `TabBar` 등을
/// 넘기면 `preferredSize` 가 자동으로 합산된다.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.bottom,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
  });

  final Widget? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AppBar(
          title: title,
          actions: actions,
          bottom: bottom,
          leading: leading,
          automaticallyImplyLeading: automaticallyImplyLeading,
          centerTitle: centerTitle,
          backgroundColor: Colors.white.withValues(alpha: 0.4),
          surfaceTintColor: Colors.transparent,
          foregroundColor: ac.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: ac.textPrimary,
          ),
          shape: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
