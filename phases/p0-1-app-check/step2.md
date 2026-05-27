# Step 2: workflow-define

## 읽어야 할 파일

먼저 아래 파일들을 읽고 프로젝트의 아키텍처와 설계 의도를 파악하라:

- `/.github/workflows/deploy_github_pages.yml` — 현재 Web 배포 워크플로. 수동 트리거 전용 (`workflow_dispatch`).
- `/RELEASE_CHECKLIST.md` — 배포 절차와 P0-1 항목.
- `/lib/main.dart` — Step 0 이후 상태. `String.fromEnvironment('RECAPTCHA_V3_SITE_KEY')` 로 사이트 키를 받는다.

이전 step 에서 만들어진 코드를 꼼꼼히 읽고, 설계 의도를 이해한 뒤 작업하라.

## 배경

Step 0 에서 main.dart 가 `--dart-define=RECAPTCHA_V3_SITE_KEY=<값>` 으로 사이트 키를 받도록 바꿨다. GitHub Pages 배포 워크플로의 `flutter build web` 라인에 해당 인자를 추가해 실제 배포 시 사이트 키가 주입되도록 한다.

사이트 키 자체는 reCAPTCHA v3 공개 키이므로 GitHub Actions Secrets 가 필수는 아니지만, 키 교체 시 코드 수정 없이 secret 만 갱신하면 되도록 Secrets 경로를 쓴다. Secret 미설정 시에는 빈 문자열이 주입되어 Step 0 의 silent skip 분기로 흘러간다 — 배포는 통과하되 App Check 만 비활성.

## 작업

`.github/workflows/deploy_github_pages.yml` 의 `Build web (base-href = /repo name/)` step 에 `--dart-define=RECAPTCHA_V3_SITE_KEY=${{ secrets.RECAPTCHA_V3_SITE_KEY }}` 인자를 추가한다.

### 변경 후 형태 (참고)

```yaml
- name: Build web (base-href = /repo name/)
  run: |
    flutter build web --release \
      --base-href "/${{ github.event.repository.name }}/" \
      --dart-define=RECAPTCHA_V3_SITE_KEY=${{ secrets.RECAPTCHA_V3_SITE_KEY }}
```

또는 단일 라인 유지를 선호한다면:

```yaml
- name: Build web (base-href = /repo name/)
  run: flutter build web --release --base-href "/${{ github.event.repository.name }}/" --dart-define=RECAPTCHA_V3_SITE_KEY=${{ secrets.RECAPTCHA_V3_SITE_KEY }}
```

둘 중 하나로 통일. 다른 step / job / on / permissions / concurrency 블록은 건드리지 마라.

### 주의

- `${{ secrets.RECAPTCHA_V3_SITE_KEY }}` 가 미설정이면 빈 문자열로 치환된다. 빌드 실패가 아니라 App Check 비활성 상태로 배포된다 (Step 0 의 silent skip 분기). 이 동작이 의도된 동작이다.
- secret 이름은 **반드시** `RECAPTCHA_V3_SITE_KEY` 로 한다. main.dart 의 `String.fromEnvironment` 키와 동일해야 한다.
- 워크플로 트리거 (`workflow_dispatch`) 를 추가/제거하지 마라. RELEASE_CHECKLIST 4-2 는 트리거 복구를 별도 절차로 분리하고 있으며 이 phase 의 범위 밖이다.

## Acceptance Criteria

- 변경 후 워크플로 YAML 이 문법적으로 유효해야 한다 (들여쓰기, 따옴표).
- `Build web` step 의 명령에 `--dart-define=RECAPTCHA_V3_SITE_KEY=${{ secrets.RECAPTCHA_V3_SITE_KEY }}` 가 포함돼야 한다.
- 다른 step / job 의 변경이 없어야 한다.

검증 자동화 명령:

```bash
python scripts/execute.py validate p0-1-app-check
```

## 검증 절차

1. 위 validate 명령을 실행한다.
2. YAML 파일을 열어 변경 라인이 의도대로 들어갔는지, 다른 블록이 의도치 않게 수정되지 않았는지 눈으로 확인한다.
3. 결과에 따라 `phases/p0-1-app-check/index.json` 의 step 2 를 업데이트한다:
   - 성공 → `"status": "completed"`, `"summary": "deploy_github_pages.yml 의 flutter build web 에 --dart-define=RECAPTCHA_V3_SITE_KEY=secrets.RECAPTCHA_V3_SITE_KEY 추가"`
   - 실패 → `"status": "error"`, `"error_message": "<구체적 에러>"`
   - secret 등록은 사용자가 GitHub UI 에서 직접 수행하므로 이 step 에서는 blocked 가 발생하지 않는다 (코드 변경만 함).

## 금지사항

- 워크플로 트리거(`on:` 블록)를 변경하지 마라. 이유: 수동 배포 전용 상태는 RELEASE_CHECKLIST 4-2 절차로 별도 관리한다.
- 다른 워크플로 파일(`.github/workflows/aggregate_stats.yml` 등) 을 건드리지 마라. 이유: 이 step 은 deploy_github_pages.yml 한 파일만 다룬다.
- secret 이름을 다르게 짓지 마라. 이유: main.dart 의 `String.fromEnvironment('RECAPTCHA_V3_SITE_KEY')` 와 정확히 일치해야 dart-define 이 동작한다.
- 사이트 키 값 자체를 워크플로 파일에 하드코딩하지 마라. 이유: 키 교체 시 코드/PR 이 필요해진다. Secrets 경로를 유지한다.
- `aggregate_stats.yml` 의 cron 복구 같은 다른 운영 작업을 끼워넣지 마라. 이유: 이 phase 범위 밖이며 RELEASE_CHECKLIST 4-1 에서 별도로 처리한다.
