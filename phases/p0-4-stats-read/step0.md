# Step 0: aggregate-script

## 읽어야 할 파일

- `/CLAUDE.md` — 프로젝트 개요, Firebase 구조
- `/RELEASE_CHECKLIST.md` — "P0-4" 섹션. `aggregates.json` / `full_report.json` / `report.md` 스키마 예시가 여기 있다. 반드시 참고하라.
- `/lib/services/global_answer_stats_service.dart` — Firestore `question_stats` 문서 구조(`attempts` / `correct` / `option_counts`) 파악
- `/assets/question_subcategory.json` — 문제 ID → 소카테고리 매핑 (소카테고리 집계에 필요)

## 배경

quiz_app 통계 화면은 Firestore `question_stats` 1,000문서를 진입할 때마다 직접 read 한다 (진입당 1,000 read). 사용자가 늘면 무료 한도를 초과한다. 해결책은 GitHub Actions 가 주기적으로 한 번만 집계해 정적 JSON 으로 만들고, 클라이언트는 그 JSON 만 받는 것이다.

이 step 은 그 집계를 수행하는 Node.js 스크립트를 만든다. GitHub Actions 워크플로는 Step 1, 클라이언트 변경은 Step 2 의 작업이다.

## 작업

### 1. `tool/package.json`

`firebase-admin` 을 의존성으로 갖는 최소 `package.json` 을 생성한다.

### 2. `tool/aggregate_stats.js`

Node.js 스크립트. `firebase-admin` 으로 Firestore 에 접속해 아래를 수행한다.

- 서비스 계정 키: 환경변수 `GOOGLE_APPLICATION_CREDENTIALS` 가 가리키는 JSON 파일로 초기화한다 (`firebase-admin` 의 `applicationDefault()`).
- `question_stats` 컬렉션 전체를 get 한다. 각 문서는 `{ attempts, correct, option_counts }`. 오답률 = `attempts > 0 ? 1 - correct / attempts : 0`.
- `user_answers` 컬렉션: 문서(uid) 개수 = `total_users`. 각 uid 의 `sessions` 서브컬렉션은 `.count()` aggregation query 로 개수만 받아 합산해 `total_sessions` 를 구한다. **sessions 문서 전체를 get 하지 마라 — read 비용을 최소화한다.**
- `assets/question_subcategory.json` 을 읽어 문제 ID → 소카테고리 태그 매핑을 만든다.

출력 디렉토리(기본 `./out`, 첫 명령행 인자로 변경 가능)에 3개 파일을 쓴다:

- `aggregates.json` — 클라이언트 통계 화면용. `{ updated_at, hardest_top10, subcategory }`. `hardest_top10` 은 `attempts >= 5` 이고 오답>0 인 문항 중 오답률 높은 상위 10개. `subcategory` 는 태그별 `{ attempts, correct }` 합 (표본 합 30 미만 태그는 제외).
- `full_report.json` — `{ updated_at, total_users, total_sessions, hardest_top20, all_questions }`. `all_questions` 는 전체 문제의 `{ attempts, correct, wrong_rate }` 맵.
- `report.md` — 사람이 읽는 마크다운. 누적 사용자/세션 수 + "가장 많이 틀리는 문제 TOP 20" 표.

정확한 JSON 스키마와 `report.md` 형식은 `RELEASE_CHECKLIST.md` 의 P0-4 Step 2·Step 3 에 예시가 있으니 그대로 따른다.

## Acceptance Criteria

```bash
node --check tool/aggregate_stats.js
```

- `node --check` 가 문법 오류 없이 통과해야 한다.
- `tool/package.json` 과 `tool/aggregate_stats.js` 가 존재해야 한다.
- 실제 Firestore 접속 실행은 서비스 계정 키가 필요하므로 이 step 의 AC 에 포함하지 않는다.

## 검증 절차

1. `node --check tool/aggregate_stats.js` 실행.
2. 산출물 스키마가 `RELEASE_CHECKLIST.md` 의 P0-4 예시와 일치하는지 확인.
3. 결과에 따라 `phases/p0-4-stats-read/index.json` 의 step 0 을 업데이트한다 (completed + summary / error + error_message).

## 금지사항

- 앱 코드(`lib/`)를 수정하지 마라. 이유: 클라이언트 변경은 Step 2 의 작업이다.
- `.github/workflows/` 를 건드리지 마라. 이유: 워크플로는 Step 1 의 작업이다.
- 서비스 계정 키 파일을 저장소에 만들거나 커밋하지 마라. 이유: 비밀 정보다. 스크립트는 환경변수로만 키를 받는다.
- 기존 테스트를 깨뜨리지 마라.
