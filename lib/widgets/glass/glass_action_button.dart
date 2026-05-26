import 'package:flutter/material.dart';

import '../../theme/app_theme_colors.dart';

/// 풀-너비 그라데이션 1차 CTA 버튼.
///
/// 글래스 톤 화면 어디서나 동일한 indigo/emerald 등 `AppThemeColors` 의
/// gradient 팔레트를 그대로 받아 그라데이션 배경 + 흰색 텍스트 + Ink ripple 을
/// 그린다. `onTap == null` 이면 indigo 12% 반투명 + indigo 텍스트로
/// 비활성 상태를 나타낸다 (정보 알약과 톤 통일).
class GlassActionButton extends StatelessWidget {
  const GlassActionButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.gradient,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onTap;
  final List<Color> gradient;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final disabled = onTap == null;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: disabled
                ? null
                : LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: disabled
                ? ac.gradientIndigo[0].withValues(alpha: 0.15)
                : null,
            border: disabled
                ? Border.all(
                    color: ac.gradientIndigo[0].withValues(alpha: 0.25),
                  )
                : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: disabled ? ac.gradientIndigo[0] : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
