# Step 1: low-impact-screens

## 읽어야 할 파일

- `/lib/screens/mock_exam_history_screen.dart`
- `/lib/screens/disqualification_detail_screen.dart`
- `/lib/widgets/glass/glass_app_bar.dart`, `glass_scaffold.dart` (Step 0)
- `/lib/theme/app_theme_colors.dart` (시맨틱 색)
- `/C:/Users/smile/.claude/plans/ui-radiant-charm.md`

## 배경

저영향 화면 2개부터 시작해 Step 0 의 공용 위젯(GlassScaffold, GlassAppBar, GlassCard borderColor, 시맨틱 색)이 실제 사용에서 정상 동작하는지 검증한다. 특히 `disqualification_detail_screen` 의 `TabBar in AppBar.bottom` 패턴이 GlassAppBar 의 `preferredSize` 계산과 잘 맞물리는지 확인하는 게 이 step 의 핵심.

## 작업

### 1. `lib/screens/mock_exam_history_screen.dart` 글래스화
- `Scaffold + AppBar` → `GlassScaffold + GlassAppBar(title: ...)`
- 카드 컨테이너 (`surfaceWhite + borderLight`) → `GlassCard`
- 합격/불합격 pill 의 `Color(0xFFDCFCE7)` / `Color(0xFFFEE2E2)` 배경 → `ac.successBg` / `ac.dangerBg`
- pill 텍스트 색 `Color(0xFF15803D)` / `Colors.red.shade800` → `ac.success` / `ac.danger`
- ListView padding.top 에 `kToolbarHeight + MediaQuery.padding.top` 보정 (extendBodyBehindAppBar 효과)

### 2. `lib/screens/disqualification_detail_screen.dart` 글래스화
- `Scaffold + AppBar(bottom: TabBar(...))` → `GlassScaffold + GlassAppBar(bottom: TabBar(...))`
- 본문 ListView 의 padding.top 보정
- TabBar indicator/label/unselected 색은 `appBarTheme.foregroundColor`(textPrimary) 를 따라가므로 별도 작업 없음. 시각 검증만 진행.
- 본문에 직접 hex 색은 거의 없음 (확인 필요)

## Acceptance Criteria

```bash
flutter analyze   # 통과
flutter test test/golden/screens_golden_test.dart  # 영향 골든 부분 갱신 후 통과
```

## 검증

- `mock_history_ko_light.png`, `disqualification_ko_light.png` 갱신
- 메인 → 모의고사 이력 / 실격 기준 진입 시 톤 일치
- TabBar 가 GlassAppBar 안에서 정상 렌더 (indicator 보임, label 식별 가능)
- 다크 모드에서 시맨틱 색이 자연스러운지 1회 검토

## 금지사항

- 본문 로직 변경 금지 (UI 톤만)
- 모의고사 이력/실격 데이터 로딩 로직 건드리지 마라
- 시트나 다른 화면 영향 없음
