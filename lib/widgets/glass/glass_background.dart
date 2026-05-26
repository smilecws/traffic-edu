import 'package:flutter/material.dart';

/// 글래스모피즘 배경. 그라데이션 + 흐릿한 원형 장식 위에 [child] 를 표시한다.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 베이스 그라데이션
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0E7FF), // indigo-100
                  Color(0xFFFAF5FF), // purple-50
                  Color(0xFFFFE4E6), // rose-100
                ],
              ),
            ),
          ),
        ),
        // 흐릿한 원형 장식 (purple)
        Positioned(
          top: 40,
          left: -40,
          child: Container(
            width: 192,
            height: 192,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(96),
              color: const Color(0xFFC084FC).withValues(alpha: 0.4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC084FC).withValues(alpha: 0.4),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),
        // 흐릿한 원형 장식 (rose)
        Positioned(
          top: 160,
          right: -40,
          child: Container(
            width: 224,
            height: 224,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(112),
              color: const Color(0xFFFB7185).withValues(alpha: 0.3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFB7185).withValues(alpha: 0.3),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),
        // 흐릿한 원형 장식 (cyan)
        Positioned(
          bottom: 80,
          left: 80,
          child: Container(
            width: 256,
            height: 256,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(128),
              color: const Color(0xFF22D3EE).withValues(alpha: 0.3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22D3EE).withValues(alpha: 0.3),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),
        // child
        Positioned.fill(child: child),
      ],
    );
  }
}
