# Step 2: exam-guide-and-question-detail

## 읽어야 할 파일

- `/lib/screens/exam_guide_screen.dart` — `ExamGuideScreen` + `PreparationGuideScreen` + `_StepCard` + `_DisqualSection`
- `/lib/screens/question_detail_screen.dart` — `_QuestionBodyCard`, `_AccuracyCompareCard`, `_OptionDistributionCard`
- `/lib/widgets/glass/*` (Step 0)
- `/lib/theme/app_theme_colors.dart` (시맨틱 색)

## 작업

### exam_guide_screen.dart
- 두 화면(`ExamGuideScreen`, `PreparationGuideScreen`) 모두 `Scaffold + AppBar` → `GlassScaffold + GlassAppBar`
- `_StepCard` 외곽 → `GlassCard`. 좌측 단계 아이콘 → `GradientIconBadge` (단계 인덱스로 7색 순환)
- `_DisqualSection` 의 `Color(0xFFFFE8E8)` 박스 + `Color(0xFF15803D)` 라벨 → `GradientIconBadge(gradient: ac.gradientRose, icon: Icons.gpp_bad_outlined)` + `ac.success`
- 본문 텍스트 `Color(0xFF15803D)` → `ac.success`
- 하단 OutlinedButton 은 유지
- ListView padding.top 보정

### question_detail_screen.dart
- `Scaffold + AppBar` → `GlassScaffold + GlassAppBar`
- `_QuestionBodyCard`, `_AccuracyCompareCard`, `_OptionDistributionCard` 외곽 → `GlassCard`
- 정답 보기 표시의 `0xFFDCFCE7` + `0xFF15803D` → `ac.successBg` + `ac.success`
- `Colors.red.shade700` / `Color(0xFF22C55E)` / `Colors.red.shade400` / `Colors.grey.shade400` → 시맨틱 색

## 검증
- `flutter analyze` 무이슈
- 골든 갱신: `exam_guide_ko_light.png` (question_detail 골든 신규는 별도 결정)
