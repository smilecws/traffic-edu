# Step 1: firestore-rules-payload

## 읽어야 할 파일

먼저 아래 파일들을 읽고 프로젝트의 아키텍처와 설계 의도를 파악하라:

- `/CLAUDE.md` — `user_answer_log_service.dart` CRITICAL 규칙 (uid 단위로 직접 조회, 클라이언트 read 차단)
- `/docs/ADR.md` — ADR-011 (Firestore 로 풀이 이력 기록)
- `/firestore.rules` — 현재 보안 규칙. `user_answers/{uid}/sessions/{sid}` 한 블록만 있다.
- `/lib/services/user_answer_log_service.dart` — 클라이언트가 실제로 write 하는 페이로드 형태. 이 파일이 만드는 문서 스키마가 rules 검증의 기준이다.
- `/lib/models/session_result.dart` — `items[i].sel` 의 형태 (List&lt;int&gt;).
- `/RELEASE_CHECKLIST.md` — P0-1 의 "(선택) firestore.rules 의 user_answers create 에 items 크기·필드 형태 검증 추가" 항목.

## 배경

Step 0 에서 App Check 를 도입했지만, 만약 App Check 가 우회되거나 토큰 enforcement 가 풀려 있을 때를 대비해 Firestore 룰에 한 줄 방어선을 더 둔다. 현 규칙은 `request.auth.uid == uid` 만 검증할 뿐 페이로드 형태를 보지 않으므로, 인증된 사용자가 임의로 거대한 문서를 적재할 수 있다.

`user_answer_log_service.dart` 가 만드는 문서 스키마:

```
{
  "display_name": string,
  "started_at": Timestamp | serverTimestamp,
  "finished_at": serverTimestamp,
  "license_kind": string | null,
  "score": int,
  "total": int,
  "items": [
    { "q": int, "sel": List<int>, "correct": bool },
    ...
  ]
}
```

`total` 은 1~50 범위(모의고사 40문항이 표준, 카테고리 연습은 가변, 여유분 포함). `items.size()` 와 `total` 이 일치해야 한다.

## 작업

`firestore.rules` 의 `user_answers/{uid}/sessions/{sid}` create 규칙에 페이로드 검증을 추가한다. 다른 곳(다른 match 블록 / `rules_version` / `service` / 바깥 `match /databases/...`) 은 건드리지 마라.

### 검증해야 할 항목

create 규칙은 아래 조건을 **모두** 만족해야 통과해야 한다:

1. `request.auth != null && request.auth.uid == uid` (기존 유지)
2. 페이로드의 **최상위 필드 집합** 이 다음과 정확히 일치한다:
   `display_name, started_at, finished_at, license_kind, score, total, items`
   - `request.resource.data.keys().hasOnly([...])` 와 `hasAll([...])` 양쪽을 사용해 정확 집합 강제.
3. 필드 타입:
   - `display_name` is string
   - `started_at` is timestamp
   - `finished_at` is timestamp
   - `license_kind` is string (또는 null 허용 — 클라이언트 코드에서 nullable 로 보내므로 `request.resource.data.license_kind == null || request.resource.data.license_kind is string`)
   - `score` is int, `0 <= score <= 50`
   - `total` is int, `1 <= total <= 50`
   - `score <= total`
   - `items` is list, `items.size() == total`
4. `items` 의 각 원소까지 깊은 검증은 Firestore rules 의 한계상 list iteration 이 불가하다. 대신 다음 정도까지만 한다:
   - `items is list`
   - `items.size() >= 1 && items.size() <= 50`
   - `items.size() == request.resource.data.total`

### update/delete/read

`update, delete: if false` 와 `read: if false` 는 그대로 유지한다.

### 참고 (작성 예시)

```
match /user_answers/{uid}/sessions/{sid} {
  allow read: if false;
  allow create: if request.auth != null
    && request.auth.uid == uid
    && request.resource.data.keys().hasOnly(
         ['display_name','started_at','finished_at','license_kind','score','total','items'])
    && request.resource.data.keys().hasAll(
         ['display_name','started_at','finished_at','score','total','items'])
    && request.resource.data.display_name is string
    && request.resource.data.started_at is timestamp
    && request.resource.data.finished_at is timestamp
    && (request.resource.data.license_kind == null
        || request.resource.data.license_kind is string)
    && request.resource.data.score is int
    && request.resource.data.score >= 0
    && request.resource.data.score <= 50
    && request.resource.data.total is int
    && request.resource.data.total >= 1
    && request.resource.data.total <= 50
    && request.resource.data.score <= request.resource.data.total
    && request.resource.data.items is list
    && request.resource.data.items.size() == request.resource.data.total;
  allow update, delete: if false;
}
```

(필드 순서·줄바꿈은 가독성에 맞게 조정해도 됨. 핵심 조건은 모두 포함.)

### App Check 토큰 강제

이번 step 에서는 **rules 에서 `request.app != null` 검사를 추가하지 마라.** 이유: enforcement 는 Firebase Console 에서 단계적으로 켜는 게 안전하다. rules 에 박아두면 모니터링 단계에서 모든 write 가 실패한다. 콘솔 enforcement 토글은 RELEASE_CHECKLIST 의 운영 절차로 분리한다.

## Acceptance Criteria

- `firestore.rules` 의 `user_answers/{uid}/sessions/{sid}` create 규칙이 위 검증 조건을 모두 포함해야 한다.
- 다른 match 블록 / rules_version / service 선언은 변경되지 않아야 한다.
- 파일 끝에 줄바꿈을 유지하라.

검증 자동화 명령은 없다 (이번 phase 는 emulator 단위 테스트를 도입하지 않음). 룰 문법 오류는 다음 단계의 `firebase deploy` (사용자가 콘솔/CLI 로 직접 수행) 에서 잡힌다.

## 검증 절차

1. `firestore.rules` 를 열어 위 검증 항목들이 모두 추가됐는지 눈으로 확인한다.
2. `user_answers` 외의 블록이 영향을 받지 않았는지 확인 (현재는 다른 블록이 없으므로 파일 전체 비교만 하면 된다).
3. `python scripts/execute.py validate p0-1-app-check` 가 통과하는지 확인.
4. 결과에 따라 `phases/p0-1-app-check/index.json` 의 step 1 을 업데이트한다:
   - 성공 → `"status": "completed"`, `"summary": "firestore.rules 의 user_answers create 에 페이로드 검증 추가 (필드 집합, 타입, score/total 범위, items.size == total)"`
   - 실패 → `"status": "error"`, `"error_message": "<구체적 에러>"`

## 금지사항

- `user_answer_log_service.dart` 를 수정하지 마라. 이유: 현 클라이언트 페이로드가 검증의 기준이며, 양쪽을 동시에 바꾸면 검증이 무의미해진다. 클라이언트가 만드는 필드 집합·타입에 맞춰 rules 를 작성한다.
- rules 에 `request.app != null` (App Check 토큰 강제) 을 넣지 마라. 이유: 단계적 enforcement 는 Firebase Console 에서 한다. rules 에 박으면 모니터링 단계에서 모든 write 가 실패한다.
- `read: if false` 를 풀지 마라. 이유: 클라이언트는 자기 풀이 이력을 다시 읽지 않는다 (CLAUDE.md 의 CRITICAL). 운영자만 콘솔에서 조회한다.
- `firebase deploy` 를 실행하지 마라. 이유: 룰 배포는 사용자가 RELEASE_CHECKLIST 절차에 따라 콘솔/CLI 로 직접 수행한다.
- 앱 코드(`lib/`), `tool/`, `.github/`, 문서(`docs/`, `CLAUDE.md`, `RELEASE_CHECKLIST.md`) 를 수정하지 마라. 이유: 이 step 은 `firestore.rules` 한 파일만 다룬다.
