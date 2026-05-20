# Step 2: client-cache-fetch

## 읽어야 할 파일

- `/CLAUDE.md` — 레이어 규칙(`services/` 는 `material.dart` import 금지), 캐시·Firestore I/O 규칙
- `/RELEASE_CHECKLIST.md` — "P0-4 Step 1·Step 2" (영구 캐시, raw URL fetch 설계)
- `/lib/services/global_answer_stats_service.dart` — 현재 `_fetchAll` / 메모리 캐시 / `loadAllStats` 구현
- `/lib/screens/stats_screen.dart` — 현재 글로벌 통계 표시 (`_buildGlobalSections`, `_aggregateBySubcategory`)

## 배경

현재 통계 화면은 Firestore `question_stats` 1,000문서를 직접 read 한다. Step 0·1 에서 GitHub Actions 가 집계 결과를 `data-aggregates` 브랜치의 `aggregates.json` 으로 만든다. 이 step 은 클라이언트가 Firestore 대신 그 정적 JSON 을 받도록 바꾼다.

`aggregates.json` 스키마:
```json
{
  "updated_at": "ISO8601 문자열",
  "hardest_top10": [ { "question_id": 1, "attempts": 0, "correct": 0, "wrong_rate": 0.0 } ],
  "subcategory": { "태그": { "attempts": 0, "correct": 0 } }
}
```

## 작업

### 1. `lib/services/global_answer_stats_service.dart`

- `_fetchAll()` 을 Firestore 컬렉션 get 대신 HTTP GET 으로 바꾼다:
  - URL: `https://raw.githubusercontent.com/smilecws/quiz/data-aggregates/aggregates.json`
  - `http` 패키지 사용 (이미 `pubspec.yaml` 에 있음).
- SharedPreferences 영구 캐시를 추가한다:
  - fetch 성공 시 응답 본문과 수신 시각을 SharedPreferences 에 저장한다.
  - TTL 1시간. `loadAllStats()` 는 메모리 캐시 → SharedPreferences 캐시(1시간 이내) → 네트워크 fetch 순으로 시도한다.
  - 네트워크 실패 시 만료된 SharedPreferences 캐시라도 사용한다(폴백). 그것도 없으면 빈 결과를 반환한다.
- `aggregates.json` 의 `hardest_top10` · `subcategory` 를 담을 수 있는 데이터 구조를 정의/사용한다. **클라이언트에서 1,000문서를 다시 집계하지 않는다.**
- 마지막 업데이트 시각(`updated_at` 또는 캐시 수신 시각)을 화면에서 쓸 수 있게 노출한다.

### 2. `lib/screens/stats_screen.dart`

- 글로벌 통계 섹션이 `aggregates.json` 의 사전 집계 결과(`hardest_top10`, `subcategory`)를 직접 표시하도록 조정한다. 클라이언트 측 1,000문서 기반 재집계 로직(`_aggregateBySubcategory` 등)은 제거한다.
- 글로벌 통계 영역에 "최근 업데이트: N시간 전" 같은 안내를 표시한다.

레이어 규칙(`CLAUDE.md`): `services/` 는 `material.dart` 위젯 import 금지. 모든 통계 I/O 는 `global_answer_stats_service.dart` 안에서만.

## Acceptance Criteria

```bash
flutter analyze
flutter test
```

- 둘 다 통과해야 한다.

## 검증 절차

1. `flutter analyze` 와 `flutter test` 를 실행한다.
2. `data-aggregates` 브랜치와 `aggregates.json` 은 아직 없을 수 있다. 그 경우 fetch 가 실패하고 폴백이 동작하는 게 정상이다 — 이 step 에서 raw URL 의 실제 응답을 보장할 필요는 없다.
3. 결과에 따라 `phases/p0-4-stats-read/index.json` 의 step 2 를 업데이트한다.

## 금지사항

- `tool/`, `.github/workflows/` 를 수정하지 마라. 이유: Step 0·1 의 산출물이다.
- `services/` 레이어에서 `material.dart` 를 import 하지 마라. 이유: `CLAUDE.md` 레이어 규칙 위반이다.
- 기존 위젯 테스트를 깨뜨리지 마라.
