# Step 3: result-screen

## 읽어야 할 파일
- `/lib/screens/result_screen.dart`
- `/lib/widgets/glass/*`, `/lib/theme/app_theme_colors.dart`

## 작업
- `Scaffold + AppBar` → `GlassScaffold + GlassAppBar` (단 `automaticallyImplyLeading: false` 유지)
- 점수 카드 외곽 → `GlassCard(borderRadius: 16)`, boxShadow 제거(글래스 보더가 대신)
- `_scoreColor` 분기: `0xFF15803D` / `Colors.red.shade700` / `Colors.orange` / `Colors.red` → `ac.success` / `ac.danger` / `ac.warning` / `ac.danger`
- `_IncorrectCard` 외곽 → `GlassCard(borderRadius: ..., borderColor: ac.dangerBorder)`, `Colors.red` / `Colors.green` 아이콘 → `ac.danger` / `ac.success`
- `Colors.grey.shade700` (해설 색) → `ac.textSecondary`
- ListView padding.top 보정

## 검증
- `flutter analyze` 무이슈
- 골든 갱신: `result_practice_ko_light.png`, `result_mock_pass_ko_light.png`, `result_mock_fail_ko_light.png`
