import 'package:flutter/material.dart';

import '../theme/app_theme_colors.dart';

/// 학습 토픽(1~16) id 를 `AppThemeColors` 의 7개 그라데이션 팔레트에 순환 매핑.
///
/// `study_screen.dart` 와 `study_card_screen.dart` 에서 공용으로 사용한다.
/// 16 토픽 ↔ 7 팔레트라 같은 그라데이션을 공유하는 토픽이 일부 생긴다(허용).
List<Color> topicGradient(BuildContext context, int topicId) {
  final ac = context.appColors;
  final palettes = <List<Color>>[
    ac.gradientEmerald,
    ac.gradientIndigo,
    ac.gradientViolet,
    ac.gradientRose,
    ac.gradientAmber,
    ac.gradientCyan,
    ac.gradientTeal,
  ];
  final idx = ((topicId - 1) % palettes.length).abs();
  return palettes[idx];
}

/// 토픽 강조색(그라데이션 시작색). 단색이 필요한 자리(텍스트, 아이콘 등)에서 사용.
Color topicAccent(BuildContext context, int topicId) {
  return topicGradient(context, topicId)[0];
}
