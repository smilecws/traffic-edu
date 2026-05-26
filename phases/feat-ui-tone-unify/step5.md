# Step 5: study-screens

## 읽어야 할 파일
- `/lib/screens/study_screen.dart`
- `/lib/screens/study_card_screen.dart`
- `/lib/utils/topic_palette.dart` (Step 0)
- `/lib/widgets/glass/*`, `/lib/theme/app_theme_colors.dart`

## 작업
### study_screen.dart
- `Scaffold + AppBar` → `GlassScaffold + GlassAppBar(title: Text('학습하기'))`
- `_StudyTopicTile`: Material+Container 외곽 → `GlassCard(borderRadius: 16, padding: zero)` + InkWell. 좌측 번호 박스 → `GradientIconBadge(topicGradient, size: 44, child: Text)`. `_accentFor` 제거, `topicGradient` 사용.
- ListView padding.top 보정

### study_card_screen.dart
- 3개 Scaffold 분기 (loading / error / 본문) 모두 `GlassScaffold + GlassAppBar`
- 상단 헤더 카드: accent box → `GlassCard`로 외곽, 36×36 박스 → `GradientIconBadge(topicGradient, child)`
- `_SubTopicTile`: Container+border → `GlassCard(borderColor: 토글 시 accent)`
- 본문 페이지 `_CardView` 의 외곽도 글래스 시도 (가독성 우선이라 현재 평면 유지가 적절할 수도)
- `_accentFor` 중복 제거 → `topic_palette.dart`
- `Color(0xFF334155)` → `ac.textPrimary` 또는 비슷한 시맨틱

## 검증
- `flutter analyze` 무이슈
- 골든 갱신: `study_index_ko_light.png`, `study_card_topic_04_ko_dark.png`, `study_card_topic_06_ko_light.png`
