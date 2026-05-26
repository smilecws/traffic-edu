# Step 1: written-exam-menu-redesign

## 읽어야 할 파일

- `/CLAUDE.md` — 레이어 규칙, 다국어 규칙
- `/driving-license-app-redesign.tsx` — **`SpatialBentoHome` 함수**(메인 대시보드 화면)가 이 step 의 디자인 시안
- `/lib/screens/written_exam_menu_screen.dart` — 현재 화면 (유지할 동작·메뉴)
- `/lib/widgets/glass/` — Step 0 산출 (`GlassBackground`, `GlassCard`, `GradientIconBadge`)
- `/lib/theme/app_theme_colors.dart` — Step 0에서 추가된 그라데이션 색 팔레트
- `/lib/l10n/app_localizations.dart` — 다국어 문자열
- `/lib/services/user_answer_stats_service.dart` — 정답률 데이터(`getOverallStats`) 필요 시 참고

## 배경

`WrittenExamMenuScreen` 을 `.tsx` 시안의 "메인 대시보드" (`SpatialBentoHome`) 디자인으로 리디자인한다. **기존 동작은 모두 유지** — `_openMockExam`, `_openWrongNote`, `_openPracticeMenu`, `_openFavorites`, `_openStats`, `_openMockExamHistory`, `_loadCounts` — UI 만 글래스모피즘+베이토 그리드로 바꾼다.

## 작업

`WrittenExamMenuScreen.build()` 를 다음 구조로 재구성한다:

### 1. 골격
`Scaffold` body 에 `GlassBackground` → `SingleChildScrollView` → `Padding(20)` → `Column`.

### 2. 헤더 (Row)
- 좌측: `Text` "안녕하세요" + 이모지 ✨ (또는 `l10n.greetHello` 활용)
- 우측: `GlassCard` 원형 (w/h 36) + `Icon(Icons.notifications_outlined)`. `onTap` 은 일단 빈 함수 또는 `_openMockExamHistory` 같은 적합 화면으로.

### 3. 통계 2분할 `GlassCard` (Row, divider)
- 좌: 진도 — `Icon(Icons.flag_outlined)` + "진도" 라벨 + 큰 숫자 `_attemptedCount`/`_totalCount` (Pretendard `FontWeight.w900`, 큰 사이즈)
- 우: 정답률 — `Icon(Icons.emoji_events_outlined)` + "정답률" 라벨 + 큰 숫자 `(correct/attempts * 100).toStringAsFixed(0)%`
  - 정답률 데이터는 `UserAnswerStatsService.getOverallStats()` 가 줌. `_loadCounts` 에 추가하거나 별도 fetch. `attempts == 0` 이면 `—` 표시.
- 가운데 1px `VerticalDivider` (또는 `Container` 1px width, 반투명 slate).

### 4. Bento 2×2 (`GridView.count(crossAxisCount: 2)` 또는 `Column` of `Row`)
각 카드 = `GlassCard` + 내부 `GradientIconBadge` + 제목 + 부제 + 우측 화살표.

- 카드 1: 모의고사 응시
  - `gradient: gradientCyan`, `icon: Icons.assignment_outlined`
  - 제목 "모의고사 응시", 부제 "실전 40문제 · 40분"
  - `onTap: () => _openMockExam(context)`
- 카드 2: 오답 다시 풀기
  - `gradient: gradientRose`, `icon: Icons.cancel_outlined`
  - 우측 상단 배지: `_wrongCount` (개수 > 0 일 때만)
  - `onTap: () => _openWrongNote(context)`
- 카드 3: 문제 풀기
  - `gradient: gradientIndigo`, `icon: Icons.description_outlined`
  - 제목 "문제 풀기", 부제 "유형별 · 랜덤 40문제"
  - `onTap: () => _openPracticeMenu(context)`
- 카드 4: 즐겨찾기
  - `gradient: gradientAmber`, `icon: Icons.star_rounded`
  - 우측 상단 배지: `_favoriteCount` (> 0 일 때)
  - `onTap: () => _openFavorites(context)`

### 5. 통계 화면·이력 진입
시안의 "메인 대시보드" 에는 통계·이력 카드가 없다. 기존 `_openStats`, `_openMockExamHistory` 진입을 유지하려면 헤더의 알림 버튼 옆에 `PopupMenuButton(icon: Icons.more_vert)` 추가:
- "통계 보기" → `_openStats(context)`
- "모의고사 이력" → `_openMockExamHistory(context)`

### 6. 데이터 매핑 원칙
- 시안의 더미값("96/1000", "78%", "87")은 절대 그대로 두지 마라. 실제 `_loadCounts` 값(`_attemptedCount`, `_totalCount`, `_wrongCount`, `_favoriteCount`) 으로 매핑.
- 정답률은 `UserAnswerStatsService.getOverallStats()` 결과의 `accuracyRate` 사용.

### 7. 다국어
시안의 한국어 문구를 그대로 박지 말고 기존 `l10n` 키 활용(`menuMockTitle`, `menuWrongTitle`, `menuPracticeTitle`, `menuFavoritesTitle` 등). 새 문구가 필요하면 `lib/l10n/app_localizations.dart` 의 4개 언어 맵에 동시 추가 (CLAUDE.md 규칙).

### 8. 레이어
`screens/` 가 `widgets/glass/` 사용 OK. `services/` 직접 사용은 `_loadCounts` 안의 기존 호출만, 화면 build 안에서 신규 Firestore 호출 금지.

## Acceptance Criteria

```bash
flutter analyze
flutter test
```

## 검증 절차

1. `flutter analyze && flutter test` 통과.
2. 화면 골격이 시안과 매칭: 인사·알림 헤더 + 통계 2분할 + Bento 2×2 + 통계·이력 진입 경로.
3. 기존 동작 6개 유지: `_openMockExam`, `_openWrongNote`, `_openPracticeMenu`, `_openFavorites`, `_openStats`, `_openMockExamHistory`.
4. 결과에 따라 `phases/feat-ui-redesign/index.json` step 1 업데이트.

## 금지사항

- `_loadCounts`, `_open*`, `_openVerbalSubcategorySheet` 등 비즈니스 로직 변경 금지. 이유: 이 step 은 UI만 바꾼다.
- `lib/services/`, `lib/models/`, `tool/`, `.github/` 수정 금지.
- 시안의 더미 데이터를 그대로 두지 마라.
- 다국어 문자열을 한국어로만 하드코딩하지 마라 — `l10n` 사용.
- 기존 테스트 깨뜨리지 마라.
