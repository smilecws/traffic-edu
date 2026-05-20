# Step 3: docs-update

## 읽어야 할 파일

- `/CLAUDE.md` — 현재 프로젝트의 정확한 기술 스택·구조. **이 파일이 최신 기준이다.**
- `/docs/ARCHITECTURE.md` — 갱신 대상. 현재 내용은 Firebase 전환 이전 상태다.
- `/docs/ADR.md` — 갱신 대상. 현재 ADR-010·011 이 옛 구조다.
- `/lib/services/` 디렉토리 전체 — 실제 존재하는 서비스 파일 목록 확인
- `/lib/services/global_answer_stats_service.dart`, `/lib/services/user_answer_log_service.dart` — 현재 Firebase 관련 서비스
- `/RELEASE_CHECKLIST.md` — "P0-4" 섹션 (외부 집계 아키텍처)

## 배경

`docs/ARCHITECTURE.md` 와 `docs/ADR.md` 가 코드와 어긋나 있다. 프로젝트는 Google Sign-In + Apps Script 접속 로그에서 Firebase(익명 인증 + Firestore)로 전환됐는데 docs 에 반영되지 않았다. `CLAUDE.md` 는 최신이다.

이 step 은 (1) docs 를 현재 Firebase 구조에 맞게 정정하고, (2) 이번 P0-4 작업(통계 read 외부 집계)을 docs 에 반영한다.

## 작업

### 1. `docs/ARCHITECTURE.md`

- 디렉토리 구조의 `services/` 목록을 실제와 일치시킨다. 존재하지 않는 `google_auth_service`, `access_log_service` 등은 제거하고, `global_answer_stats_service`, `user_answer_log_service` 등 실제 파일을 반영한다. **`lib/services/` 를 직접 확인해 목록을 맞춘다.**
- `config/access_log_config.dart` 언급을 `firebase_options.dart` 로 정정한다.
- "데이터 흐름" 절에서 Google `signInSilently` / `AccessLogService` 를 Firebase 익명 인증 / Firestore 기록으로 정정한다.
- 자산 경로 오류를 정정한다: `assets/questions_images/` → `assets/images/` (실제 디렉토리명).
- P0-4 외부 집계 데이터 흐름을 새로 추가한다: 통계 화면이 Firestore 직접 read 대신, GitHub Actions 가 4시간마다 집계해 `data-aggregates` 브랜치에 만든 `aggregates.json` 을 클라이언트가 HTTP fetch + SharedPreferences 캐시 한다.

### 2. `docs/ADR.md`

- ADR-010(PIPA 동의 + Google Sign-In), ADR-011(Apps Script 접속 로그) 을 현재 구조(Firebase 익명 인증, Firestore `question_stats` / `user_answers`)에 맞게 갱신한다.
- 새 ADR 을 추가한다 — 통계 read 외부 집계:
  - 결정: GitHub Actions cron 집계 + 클라이언트 raw URL fetch.
  - 이유: Firestore read 무료 한도, 클라이언트 read 0.
  - 트레이드오프: 4시간 신선도 지연.
  - 별도 `data-aggregates` 브랜치를 쓰는 이유: Flutter 웹 service worker 캐싱 회피, `main` 오염 방지.

## Acceptance Criteria

```bash
python scripts/execute.py validate p0-4-stats-read
```

- placeholder 검사를 통과해야 한다. 환경변수 `PYTHONUTF8=1` 이 필요할 수 있다 (Windows).
- docs 에 `{한글...}` 형태의 미완성 placeholder 를 남기지 마라.

## 검증 절차

1. 위 `validate` 를 실행한다.
2. `ARCHITECTURE.md` 의 `services/` 목록이 실제 `lib/services/` 와 일치하는지 확인한다.
3. `ADR.md` 에 P0-4 외부 집계 ADR 이 추가됐는지 확인한다.
4. 결과에 따라 `phases/p0-4-stats-read/index.json` 의 step 3 을 업데이트한다.

## 금지사항

- 코드(`lib/`, `tool/`, `.github/`)를 수정하지 마라. 이유: 이 step 은 문서 갱신만 한다.
- docs 에 `{한글}` 형태의 placeholder 를 남기지 마라. 이유: harness 가드레일 검증(`_validate_guardrails`)이 막아 다음 실행이 중단된다.
- `CLAUDE.md` 를 수정하지 마라. 이유: `CLAUDE.md` 는 이미 최신이며 이 step 의 기준 문서다.
- 기존 테스트를 깨뜨리지 마라.
