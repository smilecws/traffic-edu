# Step 6: quiz-screen-and-pretendard

## 읽어야 할 파일
- `/lib/screens/quiz_screen.dart` (700+줄, 특별 처리)
- `/lib/widgets/glass/*`, `/lib/theme/app_theme_colors.dart`

## 작업
- `Scaffold + AppBar` (loading + 본문 2곳) → `GlassScaffold + GlassAppBar`
- 외곽만 글래스화. 본문 컨테이너(문제·해설 박스)는 시인성 위해 **평면 유지**
- `import 'package:google_fonts/google_fonts.dart';` 제거
- `GoogleFonts.jua(...)` 4곳 → `TextStyle(fontFamily: 'Pretendard', fontWeight: ...)`:
  - 보기 번호: w700
  - 보기 본문: w500
  - 이미지 캡션: w600
  - 해설: w500
- 직접 hex/Material 색 → 시맨틱:
  - `_optionColor` 의 `0xFFDCFCE7`/`0xFFFEE2E2` → `ac.successBg`/`ac.dangerBg`
  - `_optionBorderColor` 의 `Colors.green`/`Colors.red` → `ac.success`/`ac.danger`
  - 타이머 chip 색
  - 정답/오답 아이콘
  - 즐겨찾기 `Colors.amber.shade700` → `ac.warning`
- pubspec 의 `google_fonts` 의존성/자산은 step7 에서 처리

## 검증
- `flutter analyze` 무이슈
- 골든 갱신: `quiz_practice_single_ko_light.png`, `quiz_practice_answered_ko_light.png`, `quiz_mock_ko_light.png`
