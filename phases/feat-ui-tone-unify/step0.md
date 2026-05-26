# Step 0: foundation

## 읽어야 할 파일

- `/CLAUDE.md` — 글래스 위젯 / 그라데이션 팔레트 규칙
- `/lib/widgets/glass/glass_background.dart`, `glass_card.dart`, `gradient_icon_badge.dart` — 기존 글래스 위젯
- `/lib/theme/app_theme_colors.dart` — `AppThemeColors` ThemeExtension 구조 (light/dark + copyWith + lerp)
- `/lib/screens/home_screen.dart` — 기준 톤
- `/C:/Users/smile/.claude/plans/ui-radiant-charm.md` — 전체 plan

## 배경

후속 step (1~6) 에서 8개 화면을 글래스 톤으로 통일할 때 반복되는 보일러플레이트(`Scaffold + AppBar` → 투명 + 블러)와 직접 hex 색 매핑을 한 곳으로 모은다. 이 step 은 부작용이 없는 신규 인프라만 추가.

## 작업

### 1. `lib/widgets/glass/glass_app_bar.dart` 신설
- `StatelessWidget` + `implements PreferredSizeWidget`
- 내부: `ClipRect(BackdropFilter(ImageFilter.blur(sigmaX:16,sigmaY:16), AppBar(backgroundColor: Colors.white.withValues(alpha:0.4), surfaceTintColor: Colors.transparent, elevation: 0, ...)))` 형태
- API: `title`, `actions`, `bottom`, `leading`, `automaticallyImplyLeading` (기본 true), `centerTitle` (기본 true)
- `preferredSize`: `Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0))`
- `titleTextStyle` 은 Pretendard w700 18sp, color `ac.textPrimary`

### 2. `lib/widgets/glass/glass_scaffold.dart` 신설
- `StatelessWidget`
- API: `appBar` (PreferredSizeWidget?), `body` (Widget required), `bottomNavigationBar` (Widget?)
- 내부: `Scaffold(backgroundColor: Colors.transparent, extendBodyBehindAppBar: true, appBar: appBar, body: GlassBackground(child: SafeArea(child: body)), bottomNavigationBar: ...)`

### 3. `lib/widgets/glass/gradient_icon_badge.dart` 확장
- `icon` 을 `IconData?` 로 변경 (기존 required 해제)
- `child` (`Widget?`) 파라미터 추가
- `assert(icon != null || child != null, 'icon 또는 child 중 하나는 제공해야 합니다')`
- build 분기: child 가 있으면 child 렌더, 아니면 Icon 렌더
- 기존 호출부 (`home_screen.dart`, `written_exam_menu_screen.dart`) 영향 없음 (named param 이라 호환)

### 4. `lib/widgets/glass/glass_card.dart` 확장
- optional `borderColor` (`Color?`) 파라미터 추가. 기본은 기존 흰색 border (alpha 0.6) 유지.
- borderColor 가 제공되면 Container 의 border 를 해당 색으로.

### 5. `lib/theme/app_theme_colors.dart` 에 시맨틱 색 7개 추가
- 필드: `success`, `successBg`, `danger`, `dangerBg`, `dangerBorder`, `warning`, `warningBg`
- light 값:
  - `success: 0xFF15803D`, `successBg: 0xFFDCFCE7`
  - `danger: 0xFFB91C1C`, `dangerBg: 0xFFFEE2E2`, `dangerBorder: 0xFFFECACA`
  - `warning: 0xFFB45309`, `warningBg: 0xFFFEF3C7`
- dark 값:
  - `success: 0xFF4ADE80`, `successBg: 0xFF14532D`
  - `danger: 0xFFFCA5A5`, `dangerBg: 0xFF7F1D1D`, `dangerBorder: 0xFF991B1B`
  - `warning: 0xFFFCD34D`, `warningBg: 0xFF78350F`
- `copyWith` 와 `lerp` 모두 7개 필드 갱신

### 6. `lib/utils/topic_palette.dart` 신설
- 함수: `List<Color> topicGradient(BuildContext context, int topicId)` — 16개 토픽 id (1~16) 를 `AppThemeColors` 의 7개 그라데이션 팔레트 (`gradientCyan`, `Rose`, `Emerald`, `Indigo`, `Amber`, `Violet`, `Teal`) 에 순환 매핑
- 순서 권장: `[emerald, indigo, violet, rose, amber, cyan, teal]` 로 7개를 풀돌리며 16개 토픽에 (`topicId - 1) % 7` 으로 매핑
- step5 에서 study_screen / study_card_screen 의 중복된 `_accentFor` 를 이 함수로 치환

## Acceptance Criteria

```bash
flutter analyze   # 통과
flutter test      # 기존 테스트 깨뜨리지 않음 (신규 위젯은 호출처가 없어 영향 없어야 함)
```

## 검증

- `flutter analyze` 무이슈
- 기존 호출부 영향 없음: `home_screen.dart`, `written_exam_menu_screen.dart` 의 `GradientIconBadge`, `GlassCard`, `AppThemeColors` 사용처가 깨지지 않음 확인
- 신규 위젯들은 아직 호출되지 않으므로 골든 갱신 없음

## 금지사항

- 기존 화면 코드 수정 금지 (이 step 은 인프라만)
- `lib/services/`, `lib/models/`, `tool/`, `.github/` 수정 금지
- 직접 `BackdropFilter` / `LinearGradient` 만들기 금지 (GlassAppBar 내부 외)
