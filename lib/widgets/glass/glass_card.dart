import 'dart:ui';

import 'package:flutter/material.dart';

/// 글래스 카드. BackdropFilter 블러 + 반투명 흰색 배경 + 흰 보더.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(16),
    this.child,
  });

  final double borderRadius;
  final EdgeInsetsGeometry padding;
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
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
