import 'package:flutter/material.dart';

/// 그라데이션 배경 + 중앙 콘텐츠(아이콘 또는 자식 위젯) 배지.
///
/// `icon` 과 `child` 중 정확히 하나만 사용한다.
/// - 아이콘: `GradientIconBadge(gradient: ..., icon: Icons.menu_book_outlined)`
/// - 숫자/문자열: `GradientIconBadge(gradient: ..., child: Text('5'))`
class GradientIconBadge extends StatelessWidget {
  const GradientIconBadge({
    super.key,
    required this.gradient,
    this.icon,
    this.child,
    this.size = 36,
    this.iconSize = 18,
    this.iconColor = Colors.white,
  }) : assert(
          icon != null || child != null,
          'icon 또는 child 중 하나는 제공해야 합니다',
        );

  final List<Color> gradient;
  final IconData? icon;
  final Widget? child;
  final double size;
  final double iconSize;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: child ?? Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}
