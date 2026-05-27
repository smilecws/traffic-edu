# Step 0: appcheck-client

## 읽어야 할 파일

먼저 아래 파일들을 읽고 프로젝트의 아키텍처와 설계 의도를 파악하라:

- `/CLAUDE.md` — 기술 스택·아키텍처 규칙 (특히 Firebase 관련 CRITICAL 항목, 데스크톱 자동 비활성화)
- `/docs/ARCHITECTURE.md` — 부팅 흐름(`_initFirebase` → `runApp(QuizApp)` → `_bootstrap()`)
- `/docs/ADR.md` — ADR-010(PIPA + Firebase 익명 인증), ADR-011(Firestore 풀이 이력), ADR-013(외부 집계)
- `/RELEASE_CHECKLIST.md` — P0-1 App Check 섹션 (요구 조치 목록과 위협 모델)
- `/lib/main.dart` — 현재 `_initFirebase()` 구현. `Firebase.initializeApp` 직후 `signInAnonymously` 호출 순서를 그대로 유지해야 한다.
- `/lib/services/global_answer_stats_service.dart` — `isSupported` getter (Web/Android/iOS 만 true, 데스크톱 false). App Check 활성화 게이트로 동일하게 사용한다.
- `/pubspec.yaml` — 현재 의존성 목록 (`firebase_core`, `firebase_auth`, `cloud_firestore` 가 이미 등록돼 있음).

## 배경

RELEASE_CHECKLIST 의 P0-1 (App Check) 작업. 봇이 REST API 로 익명 로그인 + `user_answers` 에 가짜 세션을 적재해 Spark 한도를 소진시키는 시나리오를 막기 위해 Web 클라이언트에 Firebase App Check 를 도입한다.

이번 phase 의 범위는 **Web 만** 이다. Android/iOS 의 Play Integrity / DeviceCheck 는 추후 P2-2 (앱스토어 배포 준비) 와 함께 처리한다. 데스크톱(Windows/macOS/Linux) 은 Firebase 미지원이라 자동 비활성화된다.

reCAPTCHA v3 사이트 키는 빌드 시 `--dart-define=RECAPTCHA_V3_SITE_KEY=...` 로 주입한다. 사이트 키가 비어 있으면 App Check activate 자체를 silent skip 한다 (로컬 dev / 키 미등록 빌드에서 앱이 깨지지 않게).

## 작업

### 1. `pubspec.yaml`

`dependencies:` 섹션에 `firebase_app_check` 를 추가한다. 다른 firebase_* 패키지 버전과 호환되는 안정판을 사용한다 (`^0.3.x` 계열). 다른 의존성 줄/순서는 건드리지 마라.

### 2. `lib/main.dart`

- `package:firebase_app_check/firebase_app_check.dart` import 추가.
- `dart:io` import 는 **하지 마라** (웹 빌드 깨짐). 플랫폼 분기는 `kIsWeb` (이미 `package:flutter/foundation.dart` 경유 가능) 만 사용한다.
- `_initFirebase()` 내부의 호출 순서를 다음과 같이 만든다:

  ```
  Firebase.initializeApp(...)
    ↓
  (Web 이고 사이트 키가 비어있지 않을 때만) FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider(<사이트 키>),
  )
    ↓
  FirebaseAuth.instance.signInAnonymously() (currentUser == null 일 때만)
  ```

- 사이트 키는 파일 상단에 `const String _recaptchaV3SiteKey = String.fromEnvironment('RECAPTCHA_V3_SITE_KEY');` 로 받는다.
- `_recaptchaV3SiteKey.isEmpty` 면 App Check activate 를 호출하지 않고 그대로 다음 단계(`signInAnonymously`) 로 진행한다. **사이트 키가 없다고 throw 하거나 앱을 멈추지 마라.**
- App Check `activate` 호출도 기존 `_initFirebase` 의 try/catch 안에서 실행된다 (실패해도 silent). 별도 try/catch 를 만들지 말고 기존 블록을 그대로 활용한다.

### 3. (참고) 시그니처

```dart
const String _recaptchaV3SiteKey =
    String.fromEnvironment('RECAPTCHA_V3_SITE_KEY');

Future<void> _initFirebase() async {
  if (!GlobalAnswerStatsService.isSupported) return;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kIsWeb && _recaptchaV3SiteKey.isNotEmpty) {
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider(_recaptchaV3SiteKey),
      );
    }
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }
}
```

(실제 구현 시 import 정렬·기존 코드 스타일 준수. `kIsWeb` 은 `package:flutter/foundation.dart` 에서 import.)

## Acceptance Criteria

```bash
flutter pub get
flutter analyze
flutter build web --release --dart-define=RECAPTCHA_V3_SITE_KEY=dummy_key_for_build_check --base-href "/quiz/"
```

- `flutter pub get` 이 `firebase_app_check` 해석에 성공해야 한다.
- `flutter analyze` 가 새 에러 없이 통과해야 한다 (기존 warning 은 무시).
- `flutter build web` 가 dart-define 으로 더미 키를 받아 정상 빌드돼야 한다. 빈 키(`--dart-define=RECAPTCHA_V3_SITE_KEY=`) 로도 빌드가 통과해야 한다.

## 검증 절차

1. 위 AC 커맨드를 실행한다.
2. 아키텍처 체크리스트:
   - `main.dart` 는 `screens/`/`services/`/플랫폼 채널만 import — `firebase_app_check` 추가는 main 전용이므로 OK.
   - `lib/services/` 의 다른 파일에 `firebase_app_check` 를 import 하지 않았는가? (한 곳에서만 활성화)
   - 데스크톱 빌드가 깨지지 않도록 `dart:io` / `Platform.isXxx` 를 쓰지 않았는가?
   - CLAUDE.md CRITICAL 규칙 미위반.
3. 결과에 따라 `phases/p0-1-app-check/index.json` 의 step 0 을 업데이트한다:
   - 성공 → `"status": "completed"`, `"summary": "firebase_app_check 추가, main.dart 에서 Web 전용 ReCaptchaV3Provider activate (사이트 키는 dart-define 으로 주입, 빈 키면 skip)"`
   - 실패 → `"status": "error"`, `"error_message": "<구체적 에러>"`
   - 사이트 키 발급 등 사용자 개입 필요 시 → `"status": "blocked"`, `"blocked_reason": "<사유>"` (이 step 자체는 사이트 키 없이도 빌드 통과해야 하므로 blocked 가 정상 발생할 일은 없다)

## 금지사항

- `lib/services/` 어느 파일에도 `firebase_app_check` 를 import 하지 마라. 이유: App Check activate 는 부팅 시 한 번만 수행되며, services 레이어가 Firebase 초기화 책임을 가지면 안 됨 (CLAUDE.md 의 레이어 경계 규칙).
- `dart:io` / `Platform.isAndroid` 등 dart:io API 를 사용하지 마라. 이유: 웹 빌드가 깨진다. 플랫폼 분기는 `kIsWeb` 으로만 한다.
- Android/iOS 용 provider (`AndroidProvider.playIntegrity`, `AppleProvider.deviceCheck`) 를 등록하지 마라. 이유: 이번 phase 범위는 Web 만이다. P2-2 와 묶어 별도 phase 에서 처리한다.
- 사이트 키가 없을 때 throw 하거나 앱 부팅을 막지 마라. 이유: dart-define 미지정 빌드(로컬 dev) 에서도 앱이 그대로 동작해야 한다. 보안은 enforcement 단계에서 끈다.
- `pubspec.yaml` 의 다른 의존성 버전을 임의로 올리지 마라. 이유: 이 step 의 범위는 `firebase_app_check` 추가 뿐.
- `lib/firebase_options.dart` 를 수정하지 마라. 이유: FlutterFire CLI 자동 생성 파일이며, App Check 는 별도 channel 이라 이 파일을 건드릴 필요가 없다.
- 기존 테스트를 깨뜨리지 마라.
