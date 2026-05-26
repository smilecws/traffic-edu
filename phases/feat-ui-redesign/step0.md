# Step 0: design-system

## 읽어야 할 파일

- `/CLAUDE.md` — 프로젝트 규칙, 테마 관련 규칙
- `/driving-license-app-redesign.tsx` — 디자인 시안 (글래스모피즘, 그라데이션 아이콘, 색 팔레트 참고)
- `/pubspec.yaml` — 의존성·폰트 등록 위치
- `/lib/theme/app_theme.dart` — `buildLightTheme` / `buildDarkTheme`
- `/lib/theme/app_theme_colors.dart` — `AppThemeColors` ThemeExtension

## 배경

`.tsx` 시안의 글래스모피즘 + 그라데이션 + Pretendard 폰트를 Flutter 로 옮기기 위한 디자인 시스템 기반을 만든다. 이후 Step 1·2 가 두 화면을 이 시스템 위에 리디자인한다.

## 작업

### 1. Pretendard 폰트 추가

다음 weight 의 `.otf` 파일을 jsdelivr CDN 에서 `assets/fonts/` 에 다운로드한다:

- `Pretendard-Regular.otf` (400)
- `Pretendard-Medium.otf` (500)
- `Pretendard-Bold.otf` (700)
- `Pretendard-ExtraBold.otf` (800)
- `Pretendard-Black.otf` (900)

URL 형식: `https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/public/static/Pretendard-{Weight}.otf`

다운로드 예시:
```bash
mkdir -p assets/fonts
curl -L -o assets/fonts/Pretendard-Regular.otf https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/public/static/Pretendard-Regular.otf
```

`pubspec.yaml` 의 `flutter.fonts` 에 family 등록:

```yaml
fonts:
  - family: Pretendard
    fonts:
      - asset: assets/fonts/Pretendard-Regular.otf
        weight: 400
      - asset: assets/fonts/Pretendard-Medium.otf
        weight: 500
      - asset: assets/fonts/Pretendard-Bold.otf
        weight: 700
      - asset: assets/fonts/Pretendard-ExtraBold.otf
        weight: 800
      - asset: assets/fonts/Pretendard-Black.otf
        weight: 900
```

### 2. `lib/theme/app_theme.dart` 갱신

`buildLightTheme` / `buildDarkTheme` 의 `textTheme` 에서 `fontFamily` 를 `'Pretendard'` 로 한다. 기존 Jua 가 `google_fonts` 로 적용돼 있다면 제거하거나, 헤딩 한정 등 정책을 결정해 명시한다.

### 3. `lib/theme/app_theme_colors.dart` 갱신

`AppThemeColors` ThemeExtension 에 그라데이션 색 팔레트를 추가한다 (`List<Color>` 필드, 길이 2):

- `gradientCyan` — `[Color(0xFF06B6D4), Color(0xFF2563EB)]` (cyan-500 → blue-600)
- `gradientRose` — `[Color(0xFFFB7185), Color(0xFFEC4899)]` (rose-400 → pink-500)
- `gradientEmerald` — `[Color(0xFF34D399), Color(0xFF14B8A6)]` (emerald-400 → teal-500)
- `gradientIndigo` — `[Color(0xFF6366F1), Color(0xFF9333EA)]` (indigo-500 → purple-600)
- `gradientAmber` — `[Color(0xFFFBBF24), Color(0xFFF97316)]` (amber-400 → orange-500)
- `gradientViolet` — `[Color(0xFFA78BFA), Color(0xFFA855F7)]` (violet-400 → purple-500)
- `gradientTeal` — `[Color(0xFF2DD4BF), Color(0xFF06B6D4)]` (teal-400 → cyan-500)

ThemeExtension 의 `copyWith` · `lerp` 메서드도 새 필드를 포함하도록 갱신. 라이트·다크 둘 다 동일 색.

### 4. `lib/widgets/glass/` 디렉토리 신설 + 3개 위젯

- **`glass_background.dart`** — `GlassBackground` `StatelessWidget`
  - `Stack` 으로 그라데이션 배경 (`LinearGradient` indigo-100 → purple-50 → rose-100)
  - 흐릿한 원형 컨테이너 3개 (purple, rose, cyan; 각각 `ImageFiltered` 또는 `Container` + `BoxDecoration(borderRadius: BorderRadius.circular(...))` + 큰 `BoxShadow blurRadius` 로 블러 효과)
  - `child` 를 위에 표시

- **`glass_card.dart`** — `GlassCard` `StatelessWidget`
  - `ClipRRect` + `BackdropFilter(filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16))`
  - `Container(color: Colors.white.withValues(alpha: 0.5))` + 흰 보더 `Colors.white.withValues(alpha: 0.6)`
  - 인자: `borderRadius` (기본 20), `padding` (기본 16), `child`

- **`gradient_icon_badge.dart`** — `GradientIconBadge` `StatelessWidget`
  - `Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient), borderRadius: BorderRadius.circular(12), boxShadow: [...]))`
  - 중앙에 `Icon(icon, color: iconColor, size: iconSize)`
  - 인자: `List<Color> gradient`, `IconData icon`, `double size` (기본 36), `double iconSize` (기본 18), `Color iconColor` (기본 `Colors.white`)

## Acceptance Criteria

```bash
flutter analyze
flutter test
```

- 둘 다 통과해야 한다.
- `assets/fonts/` 에 Pretendard 5개 weight 파일이 존재해야 한다.

## 검증 절차

1. `flutter analyze && flutter test` 실행.
2. `assets/fonts/Pretendard-{Regular,Medium,Bold,ExtraBold,Black}.otf` 5개 파일 존재 확인.
3. `pubspec.yaml` 의 `flutter.fonts` 에 Pretendard family 등록 확인.
4. `lib/widgets/glass/` 에 3개 파일 존재 확인.
5. 결과에 따라 `phases/feat-ui-redesign/index.json` 의 step 0 업데이트.

## 금지사항

- `lib/screens/` 수정 금지. 이유: 화면 리디자인은 Step 1·2 작업이다.
- `lib/services/`, `lib/models/`, `tool/`, `.github/` 수정 금지.
- 기존 위젯(`lib/widgets/` 의 기타 파일) 수정 금지 — `widgets/glass/` 만 신설.
- 기존 테스트 깨뜨리지 마라.
