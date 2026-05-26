# Step 2: home-screen-redesign

## 읽어야 할 파일

- `/CLAUDE.md` — 레이어 규칙, 다국어 규칙
- `/driving-license-app-redesign.tsx` — **`SpatialBentoMenu` 함수**(초심찾기 메뉴 화면)가 이 step 의 디자인 시안
- `/lib/screens/home_screen.dart` — 현재 화면 (유지할 메뉴 진입)
- `/lib/screens/exam_guide_screen.dart` — `openEducationSchedulePage`, `openSchedulePage` 정적 메서드 (외부 페이지 진입)
- `/lib/screens/study_screen.dart`, `/lib/screens/written_exam_menu_screen.dart`, `/lib/screens/exam_guide_screen.dart` (PreparationGuideScreen 포함) — 진입 대상 화면들
- `/lib/widgets/glass/` — Step 0 위젯
- `/lib/theme/app_theme_colors.dart`
- `/lib/l10n/app_localizations.dart`

## 배경

`HomeScreen` 을 `.tsx` 시안의 "초심찾기" (`SpatialBentoMenu`) 디자인으로 리디자인한다. **기존 진입 동작 유지** — `StudyScreen`, `WrittenExamMenuScreen`, `ExamGuideScreen`, `PreparationGuideScreen`, `openEducationSchedulePage`, `openSchedulePage`. 시안에 있는데 quiz_app 에 없는 항목(강의 통계·예약 정보·FAQ)은 "준비 중" 플레이스홀더로.

## 작업

`HomeScreen.build()` 를 다음 구조로 재구성한다:

### 1. 골격
`Scaffold` body 에 `GlassBackground` → `SafeArea` → `SingleChildScrollView` → `Padding(20)` → `Column`.

### 2. 헤더 (Row)
- 좌측 `Column`: 작은 라벨 "초심찾기" (uppercase tracking-wide 스타일 — Pretendard `FontWeight.w700` 11sp) + 큰 제목 "도로교통법" (`FontWeight.w900` 22sp)
- 우측: `GlassCard` 원형 (w/h 36) + `Icon(Icons.more_vert)` → `PopupMenuButton` 으로 기존 `_confirmRevokeConsent` (동의 철회) 메뉴 유지.

### 3. 빠른 진입 통계바 `GlassCard` (Row, 3분할)
시안의 강의/준비/예약 3분할. 각 항목은 작은 아이콘 + 라벨 + 큰 숫자 + 보조 텍스트.

- 강의 — `Icon(Icons.menu_book_outlined)` + "강의" + **"준비 중"** (큰 자리에 dash `—` 또는 "준비")
- 준비 — `Icon(Icons.check_box_outlined)` + "준비" + **"준비 중"**
- 예약 — `Icon(Icons.event_available_outlined)` + "예약" + **"준비 중"**

세 항목 모두 데이터 없음 → 동일한 "준비 중" 표시.

### 4. 메인 2분할 (Row)
- 학습하기 `GlassCard` + `GradientIconBadge(gradient: gradientEmerald, icon: Icons.menu_book_outlined)` + 제목 + 부제 "개념과 자료로 차분히"
  - `onTap`: `Navigator.push(StudyScreen())`
- 문제 풀기 `GlassCard` + `GradientIconBadge(gradient: gradientIndigo, icon: Icons.description_outlined)` + 제목 + 부제 "모의고사 · 연습 · 오답"
  - `onTap`: `Navigator.push(WrittenExamMenuScreen())`

### 5. 가로 3분할 (Row)
세로 카드, 중앙 정렬 텍스트.

- 면허시험 순서 — `gradientViolet` + `Icons.format_list_numbered` + "면허시험\n순서" + 작은 배지 "5단계"
  - `onTap`: `Navigator.push(ExamGuideScreen())`
- 준비물 가이드 — `gradientTeal` + `Icons.check_box_outlined` + "준비물\n가이드"
  - `onTap`: `Navigator.push(PreparationGuideScreen())`
- 자주묻는 질문 — `gradientAmber` + `Icons.star_rounded` + "자주묻는\n질문" + 배지 "NEW"
  - **플레이스홀더** — `onTap`: `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('준비 중인 기능입니다')))`.

### 6. 외부 페이지 섹션 `GlassCard` (Column)
- 헤더 Row: `Icon(Icons.open_in_new, 12sp)` + 작은 라벨 "도로교통공단 · 외부 페이지" (Pretendard `FontWeight.w700` 11sp, uppercase tracking-wide)
- 항목 1 (Row): `GradientIconBadge(gradient: gradientRose, icon: Icons.school_outlined, size: 32)` + Column(제목 "특별교육 일정" + 부제 "지역별 교육 일정 확인") + 우측 `Icon(Icons.north_east)` 또는 `Icons.launch`
  - `onTap`: `ExamGuideScreen.openEducationSchedulePage(context)`
- 항목 2: `gradientIndigo` (또는 blue→indigo 류) + `Icons.event_available_outlined` + "면허시험 일정" + "전국 시험장 일정 조회"
  - `onTap`: `ExamGuideScreen.openSchedulePage(context)`
- 두 항목 사이 얇은 divider.

### 7. 다국어
기존 `l10n` 키 활용 (`navExamOrder`, `navPrep`, `navEduSchedule`, `navTestSchedule`, `homeMenuExamOrderSub` 등). 신규 문구 (예: "준비 중") 가 필요하면 `lib/l10n/app_localizations.dart` 의 4개 언어 맵에 동시 추가.

### 8. 레이어
`screens/` 가 `widgets/glass/` 사용 OK. 기존 `_confirmRevokeConsent` 유지.

## Acceptance Criteria

```bash
flutter analyze
flutter test
```

## 검증 절차

1. `flutter analyze && flutter test` 통과.
2. 화면 골격이 시안과 매칭: 헤더 + 통계바 3분할 + 메인 2분할 + 가로 3분할 + 외부페이지 섹션.
3. 기존 진입 동작 유지: `StudyScreen`, `WrittenExamMenuScreen`, `ExamGuideScreen`, `PreparationGuideScreen`, `openEducationSchedulePage`, `openSchedulePage`, `_confirmRevokeConsent`.
4. "준비 중" 플레이스홀더 (강의·준비·예약 3분할, 자주묻는 질문) onTap 시 SnackBar 또는 흐릿한 비활성 스타일.
5. 결과에 따라 `phases/feat-ui-redesign/index.json` step 2 업데이트.

## 금지사항

- `_confirmRevokeConsent` 등 기존 로직 변경 금지.
- `lib/services/`, `lib/models/`, `tool/`, `.github/` 수정 금지.
- 시안의 더미 데이터("12강 3강 수강", "3/7", "12.4") 를 그대로 두지 마라 — 데이터 없음 → "준비 중".
- 다국어 문자열을 한국어로만 하드코딩하지 마라.
- 기존 테스트 깨뜨리지 마라.
