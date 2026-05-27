# Step 3: docs-update

## 읽어야 할 파일

먼저 아래 파일들을 읽고 프로젝트의 아키텍처와 설계 의도를 파악하라:

- `/CLAUDE.md` — 갱신 대상. 기술 스택과 명령어 섹션이 P0-1 이후 부정확해진다.
- `/docs/ARCHITECTURE.md` — 갱신 대상. "데이터 흐름 — 앱 부팅" 절의 `_initFirebase()` 흐름.
- `/docs/ADR.md` — 갱신 대상. 새 ADR(App Check 도입) 을 추가한다.
- `/RELEASE_CHECKLIST.md` — 갱신 대상. P0-1 섹션의 체크박스와 운영 절차.
- `/lib/main.dart` — Step 0 이후 상태. `_recaptchaV3SiteKey` 상수, `kIsWeb` 분기, silent skip 동작.
- `/firestore.rules` — Step 1 이후 상태. 페이로드 검증 추가.
- `/.github/workflows/deploy_github_pages.yml` — Step 2 이후 상태. dart-define 인자.

이전 step 에서 만들어진 코드를 꼼꼼히 읽고, 설계 의도를 이해한 뒤 작업하라.

## 배경

P0-1 (App Check) 도입을 마무리하며 문서를 현실에 맞춘다. 코드/룰/워크플로 변경은 모두 끝났고, 남은 작업은 (1) 부팅 흐름 문서화, (2) ADR 추가, (3) 운영자에게 reCAPTCHA v3 사이트 키 발급 / GitHub Secrets 등록 / Firebase Console enforcement 토글 절차를 명시하는 것이다.

이번 phase 의 범위는 Web 만이라는 점, Android/iOS 는 P2-2 와 함께 진행한다는 점, rules 에는 `request.app != null` 을 박지 않고 콘솔 enforcement 로 단계적 적용한다는 점을 문서에 반영한다.

## 작업

### 1. `docs/ARCHITECTURE.md`

- "데이터 흐름 — 앱 부팅 (인증 게이트)" 절의 `_initFirebase()` 단계에 App Check activate 한 줄을 추가한다. Web 한정, `kIsWeb && _recaptchaV3SiteKey.isNotEmpty` 분기, 실패 시 silent skip 임을 명시.
- "플랫폼별 주의" 절에 데스크톱은 App Check 도 자동 비활성(`GlobalAnswerStatsService.isSupported` 가 false) 임을 한 줄 추가하거나 기존 줄에 흡수.
- 다른 절은 건드리지 마라.

### 2. `docs/ADR.md`

- 마지막 ADR 뒤에 **ADR-016: Web 클라이언트 App Check 도입 (reCAPTCHA v3)** 을 추가한다.
- 포함할 내용:
  - **결정**: Web 빌드에 한해 `firebase_app_check` + ReCaptchaV3Provider 활성화. 사이트 키는 `--dart-define=RECAPTCHA_V3_SITE_KEY=...` 빌드 인자로 주입. 키 미주입 시 silent skip. Android/iOS 는 P2-2 (앱스토어 배포 준비) 와 함께 처리.
  - **이유**: 봇이 REST API 로 익명 로그인 + `user_answers` 가짜 세션 적재 시나리오 방어. 클라이언트 read 는 외부 집계로 0 이라(ADR-013) read 남용 위험은 없고, write 만 막으면 충분.
  - **트레이드오프**: reCAPTCHA v3 는 사용자에게 보이지 않지만 Google 도메인으로 트래픽이 가므로 사적/특수 네트워크에서 점수가 낮게 나올 가능성. enforcement 는 콘솔에서 모니터링 단계로 시작해 단계적으로 켠다. rules 에는 `request.app != null` 을 박지 않음 (rules 에 박으면 enforcement 단계 조정이 불가능해 모든 write 가 한 번에 실패할 위험).
  - **함께 추가된 보강**: `firestore.rules` 의 `user_answers` create 페이로드 검증(필드 집합·타입·`items.size == total`). App Check 우회 시 한 줄 방어선.

### 3. `CLAUDE.md`

- "기술 스택" 섹션의 Firebase 줄에 `firebase_app_check` 를 추가하고 "Web 클라이언트 App Check (reCAPTCHA v3) 활성화. 사이트 키는 `--dart-define=RECAPTCHA_V3_SITE_KEY` 로 주입" 한 줄을 덧붙인다.
- "명령어" 섹션의 `flutter build web` 예시에 `--dart-define=RECAPTCHA_V3_SITE_KEY=<reCAPTCHA v3 사이트 키>` 인자를 추가한다.
- 그 외 다른 규칙·항목은 절대 건드리지 마라.

### 4. `RELEASE_CHECKLIST.md`

- P0-1 섹션의 체크박스를 현 상태에 맞춰 갱신한다:
  - [x] `pubspec.yaml`에 `firebase_app_check` 추가
  - [x] `lib/main.dart` 초기화부에 `FirebaseAppCheck.instance.activate(...)` 추가 (Web 한정, dart-define 으로 사이트 키 주입)
  - [x] `firestore.rules` 의 `user_answers` create 에 `items` 크기·필드 형태 검증 추가
  - [x] `.github/workflows/deploy_github_pages.yml` 의 `flutter build web` 에 dart-define 인자 추가
  - [ ] Firebase Console → App Check → Web 앱에 reCAPTCHA v3 사이트 키 등록 (운영자 직접 수행)
  - [ ] GitHub 저장소 Settings → Secrets → `RECAPTCHA_V3_SITE_KEY` 추가 (운영자 직접 수행)
  - [ ] `firebase deploy --only firestore:rules` 로 룰 재배포 (운영자 직접 수행)
  - [ ] Firebase Console App Check enforcement: 우선 **모니터링** 모드로 시작 → 1~2주 정상 트래픽 확인 후 **enforce** 로 전환 (운영자 직접 수행)
  - [ ] Android/iOS Play Integrity / DeviceCheck — P2-2 와 함께 처리 (이번 phase 범위 외)
- 가능하면 P0-1 섹션 상단의 "현재 상태" / "조치" 서술을 갱신해 도입 후 상태를 반영한다 (전체를 갈아엎지 말고 변경된 사실만 정정).
- 권장 실행 순서 표의 1번 행을 ✅ 로 갱신하거나 P0 잔여 작업 설명을 갱신한다 (P0-1 도 완료됐으므로 "남은 P0 작업은 P0-1 하나뿐" 문장을 정리).

## Acceptance Criteria

```bash
python scripts/execute.py validate p0-1-app-check
```

- placeholder 검사를 통과해야 한다 (`{한글…}` 형태의 미완성 placeholder 금지).
- 환경변수 `PYTHONUTF8=1` 이 필요할 수 있다 (Windows).

## 검증 절차

1. 위 validate 명령을 실행한다.
2. 4개 문서가 P0-1 도입 후 상태와 일치하는지 확인한다.
3. CLAUDE.md 의 `question_stats` / Firebase / 외부 집계 관련 다른 항목이 의도치 않게 수정되지 않았는지 비교 확인한다.
4. 결과에 따라 `phases/p0-1-app-check/index.json` 의 step 3 을 업데이트한다:
   - 성공 → `"status": "completed"`, `"summary": "ARCHITECTURE.md/ADR.md/CLAUDE.md/RELEASE_CHECKLIST.md 갱신, ADR-016(Web App Check 도입) 신설, 운영자 잔여 액션 명시"`
   - 실패 → `"status": "error"`, `"error_message": "<구체적 에러>"`

## 금지사항

- 코드(`lib/`, `tool/`, `.github/`, `firestore.rules`, `pubspec.yaml`)를 수정하지 마라. 이유: 이 step 은 문서 갱신만 한다. 코드 변경은 step 0~2 에서 끝났다.
- CLAUDE.md 에서 App Check 와 무관한 규칙을 건드리지 마라. 이유: CLAUDE.md 는 harness 가드레일이며 다른 규칙 변경은 이 phase 범위 밖이다.
- 문서에 `{한글}` 형태의 placeholder 를 남기지 마라. 이유: harness 가드레일 검증이 막아 다음 실행이 중단된다.
- ADR-016 에 "추후 결정", "TBD" 같은 미정 사항을 남기지 마라. 이유: ADR 은 의사결정 시점 스냅샷이며, 미정 사항은 다른 ADR / RELEASE_CHECKLIST 항목으로 분리한다.
- Android/iOS App Check 를 이 phase 에서 처리한 것처럼 문서에 적지 마라. 이유: 실제 코드는 Web 만 활성화돼 있다. Android/iOS 는 P2-2 와 함께 처리한다고 명시한다.
- RELEASE_CHECKLIST 의 다른 섹션(P0-3, P1-x, P2-x) 을 임의로 수정하지 마라. 이유: 이 phase 범위는 P0-1 섹션과 권장 실행 순서 표의 1번 행 뿐.
