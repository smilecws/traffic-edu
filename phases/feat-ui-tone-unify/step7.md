# Step 7: cleanup

## 작업
1. `test/golden/_helpers.dart` 에서 `google_fonts` import + `GoogleFonts.config.allowRuntimeFetching = true` 라인 제거. `fontFamilyFallback` 은 유지.
2. `pubspec.yaml` 정리:
   - `dependencies:` 의 `google_fonts: ^6.2.1` 제거
   - `flutter.fonts:` 의 `Jua` family 항목 (만약 등록되어 있다면) 제거
   - `assets:` 의 `google_fonts/Jua-Regular.ttf` 자산 제거
   - `flutter pub get`
3. `google_fonts/` 폴더의 Jua-Regular.ttf 자산 파일 삭제 (선택; LICENSE 는 유지 가능)
4. `docs/ADR.md` 에 ADR-015 추가 (UI 톤 통일 확산, GlassAppBar/GlassScaffold 신설, 시맨틱 색, google_fonts 제거)
5. `docs/UI_GUIDE.md` / `docs/ARCHITECTURE.md` / `CLAUDE.md` / `README.md` 에 Jua/google_fonts 언급 정리
6. 전체 회귀: `flutter analyze && flutter test`
7. `phases/feat-ui-tone-unify/index.json` 모든 step `completed` 처리 + `completed_at`. `phases/index.json` 의 phase entry 도 `completed`.

## 검증
- `flutter analyze` 무이슈
- `flutter test` 전체 통과
