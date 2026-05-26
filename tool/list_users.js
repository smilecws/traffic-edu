#!/usr/bin/env node
// tool/list_users.js
//
// 운영자 로컬 전용. Firebase Auth 익명 사용자 목록을 마크다운 한 파일로 출력한다.
// 컬럼: UID · displayName(동의 시 입력한 이름) · 가입일 · 최근 로그인 · 세션 수.
//
// ⚠️ 산출물(tool/users_private.md)에는 사용자 이름이 들어 있다 — 절대 git commit 금지.
//    .gitignore 에 등록돼 있으니 기본 출력 경로를 바꾸지 말 것.
// ⚠️ GitHub Actions 등 공개 환경에서 실행 금지. 본인 PC 에서만 실행.
//
// 준비:
//   1. Firebase Console → 프로젝트 설정 → 서비스 계정 → 새 비공개 키 생성 (JSON)
//      (GitHub Secret FIREBASE_SERVICE_ACCOUNT 에 등록한 것과 같은 키를 재사용해도 됨)
//   2. 키 JSON 을 저장소 밖(예: C:\tmp)에 둔다.
//
// 실행 (PowerShell):
//   $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\tmp\serviceAccountKey.json"
//   npm install --prefix tool
//   node tool/list_users.js
//
// 출력 경로를 바꾸려면 인자로 전달: node tool/list_users.js C:\tmp\users.md

import { writeFile } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT_FILE = process.argv[2] || join(__dirname, 'users_private.md');

initializeApp({ credential: applicationDefault() });
const auth = getAuth();
const db = getFirestore();

// ── KST 시각 포맷 (Auth metadata 는 UTC 문자열) ──────────────────────────────

function fmtKst(input) {
  if (!input) return '';
  const d = new Date(input);
  if (Number.isNaN(d.getTime())) return '';
  const kst = new Date(d.getTime() + 9 * 60 * 60 * 1000);
  const p = (n) => String(n).padStart(2, '0');
  return `${kst.getUTCFullYear()}-${p(kst.getUTCMonth() + 1)}-${p(kst.getUTCDate())}`
    + ` ${p(kst.getUTCHours())}:${p(kst.getUTCMinutes())}`;
}

// 마크다운 표 셀 escape (| 와 줄바꿈이 표를 깨뜨리지 않도록)
function cell(v) {
  return String(v ?? '').replace(/\r?\n/g, ' ').replace(/\|/g, '\\|');
}

// ── Auth 사용자 전체 수집 (1,000명 초과 시 페이지네이션) ─────────────────────

async function fetchAllUsers() {
  const users = [];
  let pageToken;
  do {
    const result = await auth.listUsers(1000, pageToken);
    for (const u of result.users) {
      users.push({
        uid: u.uid,
        displayName: u.displayName ?? '',
        createdAt: u.metadata.creationTime ?? '',
        lastSignInAt: u.metadata.lastSignInTime ?? '',
      });
    }
    pageToken = result.pageToken;
  } while (pageToken);
  return users;
}

// ── 사용자별 세션 수 (user_answers/{uid}/sessions 의 count) ──────────────────

async function fetchSessionCount(uid) {
  try {
    const snap = await db
      .collection('user_answers')
      .doc(uid)
      .collection('sessions')
      .count()
      .get();
    return snap.data().count;
  } catch {
    return 0;
  }
}

// ── main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('Fetching auth users...');
  const users = await fetchAllUsers();
  console.log(`  ${users.length} users`);

  console.log('Counting sessions per user...');
  for (let i = 0; i < users.length; i++) {
    users[i].sessionCount = await fetchSessionCount(users[i].uid);
    if ((i + 1) % 50 === 0) console.log(`  ${i + 1}/${users.length}`);
  }

  // 가입일 최신순 (콘솔 Users 목록과 동일한 정렬)
  users.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

  const withName = users.filter((u) => u.displayName.trim() !== '').length;
  const totalSessions = users.reduce((s, u) => s + u.sessionCount, 0);

  const lines = [
    '# 사용자 목록 (비공개 — git commit 금지)',
    '',
    `> 생성 시각: ${fmtKst(new Date().toISOString())} (KST)`,
    '> ⚠️ displayName(사용자 이름)이 포함된 개인정보 파일입니다.'
      + ' 절대 git 에 commit 하거나 외부에 공유하지 마세요.',
    '',
    '## 요약',
    `- 전체 익명 사용자: **${users.length}명**`,
    `- 이름 입력(동의 완료): **${withName}명**`,
    `- 누적 세션: **${totalSessions}회**`,
    '',
    '## 사용자',
    '',
    '| # | 이름 | 세션 | 가입일(KST) | 최근 로그인(KST) | UID |',
    '|---|------|------|-------------|------------------|-----|',
  ];

  users.forEach((u, i) => {
    const name = u.displayName.trim() === ''
      ? '_(이름 없음)_'
      : cell(u.displayName);
    lines.push(
      `| ${i + 1} | ${name} | ${u.sessionCount}`
      + ` | ${fmtKst(u.createdAt)} | ${fmtKst(u.lastSignInAt)}`
      + ` | \`${cell(u.uid)}\` |`,
    );
  });
  lines.push('');

  await writeFile(OUT_FILE, lines.join('\n'), 'utf-8');
  console.log(`\nDone. -> ${OUT_FILE}`);
  console.log(`  ${users.length} users, ${withName} named, ${totalSessions} sessions`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
