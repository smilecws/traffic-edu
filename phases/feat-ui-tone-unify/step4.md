# Step 4: stats-screen

## 읽어야 할 파일
- `/lib/screens/stats_screen.dart` (~880줄, 가장 큰 변경 면적)
- `/lib/widgets/glass/*`, `/lib/theme/app_theme_colors.dart`

## 작업
- `Scaffold + AppBar` → `GlassScaffold + GlassAppBar(title: l10n.statsTitle)`
- 내부 카드 위젯 모두 GlassCard:
  - `_OverallStatsCard` — 외곽 + `_StatChip` 3개 40×40 박스 → `GradientIconBadge`(Cyan/Emerald/Rose)
  - `_MockExamChart` — 차트 막대 색 시맨틱화
  - `_HardestQuestionsList` / `_GlobalHardestQuestionsList` — 외곽 + 좌측 32×32 번호 박스 → `GradientIconBadge(gradientRose, child: Text(번호))`
- 직접 hex/Material 색 매핑:
  - `Color(0xFF15803D)` / `Color(0xFF22C55E)` → `ac.success`
  - `Color(0xFFDCFCE7)` / `Color(0xFFFEE2E2)` → `ac.successBg` / `ac.dangerBg`
  - `Colors.red.shade700`/400 → `ac.danger`
- ListView padding.top 보정

## 검증
- `flutter analyze` 무이슈
- 골든 갱신: `stats_ko_light.png`
