import 'dart:ui';

import 'package:flutter/material.dart';

/// 글래스 카드. BackdropFilter 블러 + 반투명 흰색 배경 + 흰 보더.
///
/// - `borderColor` 를 지정하면 흰색 기본 보더 대신 강조 색 보더로 그린다
///   (예: study 카드의 아코디언 토글 시 accent border).
/// - `backgroundColor` 를 지정하면 기본 반투명 흰색 대신 그 색을 사용한다
///   (예: quiz 옵션 카드의 정답/오답 상태별 틴트).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.backgroundColor,
    this.child,
  });

  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.6),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
