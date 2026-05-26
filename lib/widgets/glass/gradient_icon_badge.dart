import 'package:flutter/material.dart';

/// 그라데이션 배경 + 중앙 아이콘 배지.
class GradientIconBadge extends StatelessWidget {
  const GradientIconBadge({
    super.key,
    required this.gradient,
    required this.icon,
    this.size = 36,
    this.iconSize = 18,
    this.iconColor = Colors.white,
  });

  final List<Color> gradient;
  final IconData icon;
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
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}
