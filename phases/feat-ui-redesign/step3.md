# Step 3: docs-update

## 읽어야 할 파일

- `/CLAUDE.md` — UI 컨벤션 추가 대상
- `/docs/ARCHITECTURE.md` — 디렉토리 구조·테마 절 갱신
- `/docs/ADR.md` — 새 ADR 추가
- `/lib/widgets/glass/` — Step 0 산출
- `/lib/theme/app_theme_colors.dart` — 그라데이션 팔레트
- `/pubspec.yaml` — Pretendard family 등록 확인용
- `/lib/screens/home_screen.dart`, `/lib/screens/written_exam_menu_screen.dart` — Step 1·2 산출

## 배경

Step 0~2 의 디자인 시스템 도입(글래스모피즘 + 그라데이션 + Pretendard)을 문서에 반영한다.

## 작업

### 1. `docs/ARCHITECTURE.md`

- `lib/` 디렉토리 구조 절에 `widgets/glass/` 항목 추가:
  - `glass_background.dart` — 그라데이션 배경 + 흐릿한 원형 블러 컨테이너
  - `glass_card.dart` — `BackdropFilter` 기반 반투명 카드
  - `gradient_icon_badge.dart` — 그라데이션 사각형 아이콘 배지
- `theme/` 절 또는 별도 절에 `AppThemeColors` 의 그라데이션 팔레트(`gradientCyan/Rose/Emerald/Indigo/Amber/Violet/Teal`) 언급.
- `assets/` 절에 `assets/fonts/Pretendard-{Regular,Medium,Bold,ExtraBold,Black}.otf` 추가. `pubspec.yaml` 의 `flutter.fonts` 에 family 등록됨을 명시.

### 2. `docs/ADR.md`

새 ADR 을 추가한다:

**ADR-014: 글래스모피즘 UI 디자인 도입**
- **결정**: `HomeScreen` 과 `WrittenExamMenuScreen` 에 글래스모피즘 + 베이토 그리드 + 그라데이션 아이콘 + Pretendard 폰트를 적용한다. 공용 위젯은 `lib/widgets/glass/` 에 두고, 그라데이션 색은 `AppThemeColors` 의 미리 정의된 팔레트를 사용한다.
- **이유**: 시안(`driving-license-app-redesign.tsx`) 적용. 시각적 풍부함과 한국어 가독성(Pretendard) 개선.
- **트레이드오프**: `BackdropFilter` 는 모든 플랫폼에서 성능 영향 가능 (특히 웹과 구형 데스크톱). 추후 프레임 드롭이 보이면 블러 강도 낮추거나 정적 그라데이션으로 폴백.

### 3. `CLAUDE.md`

"아키텍처 규칙" 절에 두 줄 추가 (기존 규칙 옆 또는 끝):

- "그라데이션 색은 `AppThemeColors` 의 `gradientCyan` / `Rose` / `Emerald` / `Indigo` / `Amber` / `Violet` / `Teal` 등 미리 정의된 팔레트만 사용한다. 화면에서 임의의 `LinearGradient` 만들지 않는다."
- "글래스모피즘 카드·배경·아이콘 배지는 `lib/widgets/glass/` 의 `GlassBackground` / `GlassCard` / `GradientIconBadge` 위젯을 사용한다. 직접 `BackdropFilter` 나 그라데이션 컨테이너를 만들지 마라."

**다른 규칙은 절대 건드리지 마라.**

## Acceptance Criteria

```bash
python scripts/execute.py validate feat-ui-redesign
```

- placeholder 검사 통과. 환경변수 `PYTHONUTF8=1` 필요 (Windows).
- 문서에 `{한글...}` 미완성 placeholder 를 남기지 마라.

## 검증 절차

1. 위 `validate` 실행.
2. `ARCHITECTURE.md` 의 `widgets/glass/` 와 `assets/fonts/` 항목 확인.
3. `ADR.md` 의 ADR-014 추가 확인.
4. `CLAUDE.md` 의 두 줄 규칙 추가 확인.
5. 결과에 따라 `phases/feat-ui-redesign/index.json` step 3 업데이트.

## 금지사항

- 코드(`lib/`, `tool/`, `.github/`, `firestore.rules`, `pubspec.yaml`) 수정 금지. 이유: 이 step 은 문서 갱신만 한다.
- `CLAUDE.md` 의 다른 규칙을 건드리지 마라.
- 문서에 `{한글}` 형태의 placeholder 를 남기지 마라.
- 기존 테스트 깨뜨리지 마라.
