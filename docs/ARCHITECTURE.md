# 아키텍처

## 디렉토리 구조
```
lib/
├── main.dart                          # QuizApp 루트 (테마·로케일·인증 부트스트랩, MaterialApp)
├── app_settings_scope.dart            # InheritedWidget: setLocale / setThemeMode / revokeConsent 전달
├── config/
│   └── access_log_config.dart         # Apps Script 엔드포인트, Web OAuth Client ID, 동의 버전 상수
├── l10n/
│   └── app_localizations.dart         # 자체 AppLocalizations (ko/en/zh/vi 문자열 맵, gen_l10n 미사용)
├── theme/
│   ├── app_theme.dart                 # buildLightTheme() / buildDarkTheme() — ThemeData 조립
│   └── app_theme_colors.dart          # AppThemeColors ThemeExtension (라이트/다크)
├── models/                            # 순수 데이터 타입, 외부 의존 없음
│   ├── question.dart                  # Question + 3가지 JSON 팩토리 + URI 노멀라이저
│   ├── session_result.dart            # 세션 내 한 문항 답안 결과
│   ├── mock_exam_history_entry.dart   # 모의고사 기록(날짜·점수·틀린 ID)
│   ├── mock_exam_license_kind.dart    # 면허 종류 enum + 합격 점수 확장
│   ├── disqualification_catalog.dart  # 실격 기준 카탈로그
│   └── study_card.dart               # StudyCard + KeyPoint + NumberEntry + LocalizedText 파서
├── services/                          # 영속 저장·에셋 로딩·외부 API (전부 static, DI 없음)
│   ├── question_service.dart          # 문제 은행 로딩 + 카테고리/랜덤 샘플링 + 언어별 캐시
│   ├── locale_service.dart            # 로케일 저장 + 언어→asset 경로 매핑
│   ├── theme_mode_service.dart        # ThemeMode 저장
│   ├── consent_service.dart           # PIPA 동의 기록 저장/로드/삭제 (SharedPreferences)
│   ├── google_auth_service.dart       # google_sign_in 래퍼 (signIn / signInSilently / idToken)
│   ├── access_log_service.dart        # Apps Script Web App 으로 이벤트 전송 + 실패 큐 관리
│   ├── attempted_questions_service.dart  # 풀어본 문항 ID set
│   ├── favorite_questions_service.dart   # 즐겨찾기 ID set
│   ├── wrong_note_service.dart        # 오답 ID set (결과 반영 시 맞힘→제거, 틀림→추가)
│   ├── user_answer_stats_service.dart # 문항별 (attempts/correct/option_counts) 누적
│   ├── mock_exam_history_service.dart # 모의고사 이력 JSON (최대 80건 FIFO)
│   ├── disqualification_catalog_service.dart  # merged JSON → DisqualificationCatalog
│   ├── study_card_service.dart        # assets/study/<id>.json → List<StudyCard>
│   ├── question_subcategory_service.dart      # 소카테고리별 문제 수 캐시
│   ├── subcategory_classifier.dart    # 문제 텍스트 → 소카테고리 ID 분류 규칙 (CLI·런타임 공용)
│   └── preference_id_codec.dart       # List<String> → Set<int> 안전 파싱
├── screens/                           # 한 파일 = 한 화면 (Navigator.push 기반, 라우트 테이블 없음)
│   ├── auth_loading_screen.dart       # 부팅 중 스피너 (ConsentService 확인 전 표시)
│   ├── consent_screen.dart            # PIPA 동의 게이트 (Google 로그인 + 이름 + 체크박스)
│   ├── home_screen.dart               # 앱 랜딩 (6개 메뉴 카드: 학습·문제·시험순서·준비·교육일정·시험일정)
│   ├── written_exam_menu_screen.dart  # "문제 풀기" 서브메뉴 (진도·점수·메뉴·실격 팁)
│   ├── study_screen.dart              # 학습하기 인덱스 (10개 소카테고리 리스트)
│   ├── study_card_screen.dart         # 소카테고리별 핵심 개념 카드 뷰어
│   ├── quiz_screen.dart               # 퀴즈 플레이어 (타이머/채점/비디오/이미지)
│   ├── result_screen.dart             # 점수·합격 판정·오답 노트 리스트
│   ├── stats_screen.dart              # 누적 통계·모의고사 이력·최다 오답 10선
│   ├── mock_exam_history_screen.dart  # 모의고사 이력 타임라인
│   ├── exam_guide_screen.dart         # 공식 시험 순서 요약 + 외부 링크 static 메서드들
│   ├── disqualification_detail_screen.dart  # 실격 기준 상세
│   └── license_placeholder_screen.dart      # 준비 중 플레이스홀더
├── utils/
│   ├── safe_external_url.dart         # url_launcher 허용 호스트 화이트리스트
│   └── subcategory_ui.dart            # 소카테고리 ID → 아이콘/색상 매핑
└── widgets/
    ├── google_sign_in_button.dart     # 조건부 export (웹이면 _web, 아니면 _stub)
    ├── google_sign_in_button_web.dart # GIS renderButton 래퍼 (웹 전용)
    └── google_sign_in_button_stub.dart # 빈 위젯 (비웹 플랫폼)

assets/
├── questions_kor.json / questions_eng.json / questions_chi.json / questions_vi.json
│                                      # 언어별 문제 은행 (3가지 포맷 공존)
├── driving_disqualification_merged.json  # 실격 기준 (기능시험 + 도로주행)
├── question_subcategory.json          # 문제 ID → 소카테고리 ID 매핑 (tool/classify_subcategory.dart 재생성)
├── study/<subcategoryId>.json         # 소카테고리별 학습 카드 (사람이 직접 작성)
├── questions_images/*.png             # 문제 본문/해설 이미지
├── questions_videos/*.mp4             # 동영상 문제
├── images/                            # 기타 앱 내 이미지 에셋
└── app_icon.png / quiz_icon.png / license_icon.png

tool/
├── classify_subcategory.dart          # question_subcategory.json 재생성 CLI
├── extract_study_seeds.dart           # 학습 카드 초안 seed 생성 (중간 산출물, git ignore)
└── generate_app_icon_png.py           # app_icon.png 재생성 스크립트 (Pillow)
```

## 레이어 & 의존 방향
```
screens/  →  services/  →  models/
   │            │
   └─ material.dart     └─ shared_preferences / rootBundle / http
   └─ video_player      └─ dart:convert
   └─ url_launcher      └─ google_sign_in (GoogleAuthService 경유)
   └─ google_fonts
```
- `models/` 는 Flutter 의존 없음 (video_player/shared_preferences import 금지). 순수 Dart 로 테스트 가능.
- `services/` 는 Flutter `services.dart`(rootBundle), `shared_preferences`, `http`, `google_sign_in` 만. Material 위젯 import 금지.
- `screens/` 만 `material.dart` / `video_player` / `url_launcher` / `google_fonts` 를 사용.
- 한 파일은 한 레이어만 참조한다. 역방향 의존(services → screens, models → services) 금지.

## 상태 관리
- **전역 UI 설정(locale / themeMode)**: `main.dart` 의 `_QuizAppState` 가 단일 진실 소스. 하위에는 `AppSettingsScope`(InheritedWidget) 으로 `setLocale` / `themeMode` / `setThemeMode` / `revokeConsent` 를 전달.
- **인증 상태**: `_QuizAppState._authState` (`_AuthState.loading` / `needConsent` / `ready`) 로 관리. `ConsentService.load()` 결과 + 플랫폼 판별로 결정.
- **퀴즈 세션 상태**: `QuizScreen` 의 `State` 로컬에 두고 세션 종료 시 일괄 커밋. 중도 이탈(`PopScope`)에도 `attempted / wrongNote / stats` 는 저장한다.
- **도메인 상태(즐겨찾기/오답/진도/통계/이력)**: `SharedPreferences` 가 단일 진실 소스. 각 서비스는 매 호출마다 load → mutate → save. 메모리 캐시 없음 (유일한 예외: `QuestionService` 의 `_allQuestions`).
- **상태 관리 라이브러리 없음**: Provider/Riverpod/Bloc 도입하지 않음. 화면 복귀 시 `await _loadCounts()` 로 명시 새로고침.

## 데이터 흐름 — 앱 부팅 (인증 게이트)
```
main() → QuizApp.initState → _bootstrap()
      ├─ LocaleService.loadPreferredLocale()   ─┐
      ├─ ThemeModeService.loadPreferred()       ├─ Future.wait (병렬)
      └─ ConsentService.load()                 ─┘
            │
            ├─ [데스크톱 Windows/macOS/Linux] → _AuthState.ready (게이트 우회)
            │
            ├─ [consent == null] → _AuthState.needConsent → ConsentScreen
            │
            └─ [consent 존재] → _AuthState.ready → HomeScreen
                   └─ fire-and-forget: GoogleAuthService.signInSilently()
                         → AccessLogService.flushPending()
                         → AccessLogService.send(eventType: 'app_launch')
```

## 데이터 흐름 — 모의고사 1회
```
[HomeScreen]
      │  "문제 풀기" 카드 탭
      ▼
[WrittenExamMenuScreen]
      │  사용자: "모의고사 응시" → 면허 종류 선택 시트
      ▼
[QuizScreen(mockExamLicenseKind, showTimerAndScore: true)]
      │
      │  initState
      ├─→ QuestionService.getRandomQuestions(count: 40)
      │         └─ loadAllQuestions() → rootBundle.loadString(언어별 JSON)
      │                                 → Question.fromJson / fromPageExport / fromPdfProblemsExport
      ├─→ FavoriteQuestionsService.loadFavoriteIds()
      │
      │  진행 중
      ├─→ 40분 Timer.periodic → 0초 시 _finishDueToTimeLimit()
      ├─→ 문항마다 SessionResult 생성 → _results 누적
      │
      │  완료 (_finalizeAndGoToResults)
      ├─→ MockExamHistoryService.addRecord(entry)        [이력]
      ├─→ WrongNoteService.applySessionResults(results)  [오답 반영]
      ├─→ AttemptedQuestionsService.markSessionAttempted(ids) [진도]
      ├─→ UserAnswerStatsService.applySessionResults(results) [문항 통계]
      │
      ▼
[ResultScreen(score, total, results, mockExamLicenseKind)]
      │  합격/불합격 판정 (licenseKind.passScoreMinOutOf100)
      │  오답 노트 리스트
      ▼
[WrittenExamMenuScreen] (Navigator.pushAndRemoveUntil)
```

## 문제 은행 포맷
`assets/questions_*.json` 은 최상위에 `questions[]` 또는 `pages[]` 를 갖는다.
- **레거시 형식**: `{ questions: [{ id, question, options, answer, explanation, images?, video? }] }` → `Question.fromJson`
- **Page export**: `{ pages: [{ questions: [{ question, choices: [{number, text}], answer: [...], explanation, images?, video? }] }] }` → `Question.fromPageExport`
- **PDF problems export**: `{ pages: [{ problems: [{ problem_area, image_area, image_description_area, explanation_area, video_area }] }] }` → `Question.fromPdfProblemsExport`

파싱 시 `images` 는 `data:image/...;base64,...` 또는 `assets/questions_images/...` 로 노멀라이즈. `video` 는 http → https 업그레이드 후 `assets/questions_videos/...` 또는 https URL 로 정리.

## 학습 카드 포맷
`assets/study/<subcategoryId>.json` 스키마:
```json
{
  "subcategory_id": "traffic_signal",
  "title": { "ko": "신호·지시", "en": "Signals" },
  "lead": { "ko": "..." },
  "key_points": [
    { "heading": { "ko": "..." }, "body": { "ko": "..." }, "law_refs": ["도로교통법 §5"] }
  ],
  "numbers": [
    { "label": { "ko": "황색 점멸" }, "value": { "ko": "서행" } }
  ],
  "example_question_ids": [1, 42, 337]
}
```
`StudyCard.fromJson` 이 파싱. `LocalizedText` 는 `{ "ko": "...", "en": "..." }` 맵이며 없는 언어는 ko 폴백.

## 영속 저장 키 (SharedPreferences)
| 키 | 타입 | 용도 |
|----|------|------|
| `app_locale_language_code` | String | UI/문제 은행 언어 |
| `app_theme_mode` | String | `light` / `dark` / `system` |
| `user_consent_v1` | String(JSON) | PIPA 동의 기록 (ConsentRecord) |
| `access_log_pending_v1` | List&lt;String&gt; | 전송 실패한 접속 로그 큐 (최대 100건) |
| `attempted_question_ids` | List&lt;String&gt; | 진도 추적 |
| `favorite_question_ids` | List&lt;String&gt; | 즐겨찾기 |
| `wrong_question_ids` | List&lt;String&gt; | 오답 노트 |
| `user_answer_stats_v1` | String(JSON) | 문항 ID → {a, c, oc[]} |
| `mock_exam_history_json_v1` | String(JSON) | 모의고사 이력 (최대 80건) |

## 플랫폼별 주의
- **웹 (Chrome)**: HTML5 video 가 WMV 미지원 → `quiz_screen.dart` 의 `_VideoCard` 가 "Windows 앱으로 실행" 카드로 폴백. 새 비디오 포맷 추가 시 이 분기도 업데이트.
- **웹 핫 리스타트**: `VideoPlayerController` 를 즉시 `dispose` 하면 다음 프레임의 `VideoPlayer` 위젯이 disposed 컨트롤러에 붙어 충돌. 반드시 `_disposeVideoLater` 로 다음 프레임 미룸.
- **웹 Google Sign-In**: GIS (Google Identity Services) 는 `signIn()` programmatic 호출이 막혀 있어 `renderButton()` 경로(`GoogleSignInWebButton`)만 동작. `init()` 완료 전 `renderButton()` 호출 금지 → `ConsentScreen._authReady` 플래그로 제어.
- **데스크톱 (Windows/macOS/Linux)**: `google_sign_in` 미지원 → `_isAuthGateSupported()` 가 `false` 반환해 동의 게이트 우회.
- **GitHub Pages 배포**: `flutter build web` → `docs/` 또는 Pages 브랜치. base href 주의 (빌드 옵션으로 조정).
