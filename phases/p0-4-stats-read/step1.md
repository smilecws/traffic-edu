# Step 1: github-actions-workflow

## 읽어야 할 파일

- `/CLAUDE.md` — 프로젝트 개요, 배포 구조
- `/RELEASE_CHECKLIST.md` — "P0-4 Step 2" 섹션 (외부 집계 아키텍처, cron 주기)
- `/.github/workflows/deploy_github_pages.yml` — 기존 워크플로 패턴 참고
- `/tool/aggregate_stats.js`, `/tool/package.json` — Step 0 산출물. 이 스크립트를 실행하는 워크플로를 만든다.

## 배경

Step 0 의 `aggregate_stats.js` 를 GitHub Actions 가 4시간마다 자동 실행하도록 워크플로를 만든다. 산출물(`aggregates.json` 등)은 `main` 이 아닌 별도 `data-aggregates` 브랜치에 commit 한다 — `main` 브랜치 오염과 Flutter 웹 재빌드를 피하기 위해서다.

## 작업

`.github/workflows/aggregate_stats.yml` 을 생성한다.

- 트리거: `schedule` cron `'0 */4 * * *'` + `workflow_dispatch` (수동 실행용).
- 실행 환경: `ubuntu-latest`, Node.js.
- 단계:
  1. 저장소 checkout.
  2. Node 셋업 후 `tool/` 의존성 설치.
  3. Secrets 의 `FIREBASE_SERVICE_ACCOUNT` (서비스 계정 키 JSON) 를 임시 파일로 쓰고 `GOOGLE_APPLICATION_CREDENTIALS` 환경변수로 지정.
  4. `node tool/aggregate_stats.js ./out` 실행.
  5. `./out` 의 `aggregates.json` / `full_report.json` / `report.md` 를 `data-aggregates` 브랜치에 commit & push.
- 임시 키 파일이 저장소에 남지 않게 한다.

## Acceptance Criteria

- `.github/workflows/aggregate_stats.yml` 이 생성되어야 한다.
- 유효한 YAML 이어야 한다. 검증:

```bash
python -c "import yaml; yaml.safe_load(open('.github/workflows/aggregate_stats.yml', encoding='utf-8'))"
```

  PyYAML 이 없으면 `pip install pyyaml` 후 실행한다. 그래도 안 되면 YAML 들여쓰기를 직접 검토한다.

## 검증 절차

1. 위 YAML 파싱 검증.
2. 워크플로 단계가 위 작업 명세와 일치하는지 확인.
3. `phases/p0-4-stats-read/index.json` 의 step 1 을 업데이트한다.
   - 이 step 은 yml 작성까지만 한다. **completed** 로 마킹하라.
   - `summary` 에 "워크플로 작성 완료. 실제 동작에는 사용자의 Secrets(`FIREBASE_SERVICE_ACCOUNT`) 등록과 `data-aggregates` 브랜치 생성이 필요" 를 적어라.

## 금지사항

- Firebase 서비스 계정 키를 발급하거나 저장소에 넣으려 하지 마라. 이유: 키 발급과 GitHub Secrets 등록은 사용자(운영자) 작업이다. 워크플로는 Secrets 를 참조만 한다.
- 이 step 을 `blocked` 로 만들지 마라. 이유: yml 파일 작성은 키 없이 가능하다. `completed` 로 끝내라.
- 앱 코드(`lib/`)나 `tool/aggregate_stats.js` 를 수정하지 마라.
- 기존 테스트를 깨뜨리지 마라.
