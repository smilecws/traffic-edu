#!/usr/bin/env node
// tool/aggregate_stats.js
// GitHub Actions cron 에서 실행. Firestore user_answers 세션 로그를
// 집계해 aggregates.json, full_report.json, report.md 를 생성한다.
//
// 사용법:
//   GOOGLE_APPLICATION_CREDENTIALS=path/to/key.json node tool/aggregate_stats.js [out_dir]

import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp, applicationDefault, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT_DIR = process.argv[2] || join(__dirname, 'out');

// ── Firebase 초기화 ──────────────────────────────────────────────────────────

initializeApp({ credential: applicationDefault() });
const db = getFirestore();

// ── Firestore 데이터 수집 ────────────────────────────────────────────────────

// user_answers/{uid} 는 부모 문서를 명시적으로 생성하지 않는 ghost ancestor 라
// .collection('user_answers').get() 은 0건을 반환한다. collectionGroup('sessions')
// 로 모든 sessions 서브컬렉션을 한 번에 읽어야 한다 (uid 무관 평면 조회).
async function fetchQuestionStats() {
  const sessionsSnap = await db.collectionGroup('sessions').get();
  const stats = {};

  for (const sessionDoc of sessionsSnap.docs) {
    const items = sessionDoc.data().items;
    if (!Array.isArray(items)) continue;

    for (const item of items) {
      const qId = String(item.q);
      if (!stats[qId]) {
        stats[qId] = { attempts: 0, correct: 0, option_counts: {} };
      }
      stats[qId].attempts += 1;
      if (item.correct === true) {
        stats[qId].correct += 1;
      }
      const sel = item.sel;
      if (Array.isArray(sel)) {
        for (const idx of sel) {
          const key = String(idx);
          stats[qId].option_counts[key] =
            (stats[qId].option_counts[key] ?? 0) + 1;
        }
      }
    }
  }

  return stats;
}

async function fetchUserCounts() {
  // listDocuments() 는 ghost ancestor 도 포함해 uid ref 를 반환한다.
  const userRefs = await db.collection('user_answers').listDocuments();
  const totalUsers = userRefs.length;

  const countSnap = await db.collectionGroup('sessions').count().get();
  const totalSessions = countSnap.data().count;

  return { totalUsers, totalSessions };
}

// ── 집계 로직 ────────────────────────────────────────────────────────────────

function computeWrongRate(attempts, correct) {
  return attempts > 0 ? 1 - correct / attempts : 0;
}

function buildHardestList(stats, topN) {
  return Object.entries(stats)
    .map(([id, s]) => ({
      question_id: Number(id),
      attempts: s.attempts,
      correct: s.correct,
      wrong_rate: computeWrongRate(s.attempts, s.correct),
    }))
    .filter((q) => q.attempts >= 5 && q.wrong_rate > 0)
    .sort((a, b) => b.wrong_rate - a.wrong_rate || b.attempts - a.attempts)
    .slice(0, topN);
}

function buildAllQuestions(stats) {
  const result = {};
  for (const [id, s] of Object.entries(stats)) {
    result[id] = {
      attempts: s.attempts,
      correct: s.correct,
      wrong_rate: computeWrongRate(s.attempts, s.correct),
      option_counts: s.option_counts,
    };
  }
  return result;
}

// ── 출력 생성 ────────────────────────────────────────────────────────────────

function buildAggregatesJson(stats, updatedAt) {
  return {
    updated_at: updatedAt,
    hardest_top10: buildHardestList(stats, 10),
    all_questions: buildAllQuestions(stats),
  };
}

function buildFullReportJson(stats, totalUsers, totalSessions, updatedAt) {
  return {
    updated_at: updatedAt,
    total_users: totalUsers,
    total_sessions: totalSessions,
    hardest_top20: buildHardestList(stats, 20),
    all_questions: buildAllQuestions(stats),
  };
}

function buildReportMd(fullReport) {
  const lines = [
    '# 테스트 통계자료',
    '',
    `> 최근 업데이트: ${fullReport.updated_at}`,
    '',
    '## 사용자 현황',
    `- 누적 사용자: **${fullReport.total_users.toLocaleString()}명**`,
    `- 누적 풀이 세션: **${fullReport.total_sessions.toLocaleString()}회**`,
    '',
    '## 가장 많이 틀리는 문제 TOP 20',
    '',
    '| 순위 | 문제 ID | 응시 | 오답률 |',
    '|------|---------|------|--------|',
  ];

  fullReport.hardest_top20.forEach((q, i) => {
    const pct = `${Math.round(q.wrong_rate * 100)}%`;
    lines.push(`| ${i + 1} | #${q.question_id} | ${q.attempts} | ${pct} |`);
  });

  lines.push('');
  return lines.join('\n');
}

// ── main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('Fetching user_answers sessions...');
  const [stats, userCounts] = await Promise.all([
    fetchQuestionStats(),
    fetchUserCounts(),
  ]);

  const updatedAt = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');

  const aggregates = buildAggregatesJson(stats, updatedAt);
  const fullReport = buildFullReportJson(
    stats,
    userCounts.totalUsers,
    userCounts.totalSessions,
    updatedAt,
  );
  const reportMd = buildReportMd(fullReport);

  await mkdir(OUT_DIR, { recursive: true });

  await Promise.all([
    writeFile(join(OUT_DIR, 'aggregates.json'), JSON.stringify(aggregates, null, 2) + '\n'),
    writeFile(join(OUT_DIR, 'full_report.json'), JSON.stringify(fullReport, null, 2) + '\n'),
    writeFile(join(OUT_DIR, 'report.md'), reportMd),
  ]);

  console.log(`Done. Output written to ${OUT_DIR}`);
  console.log(`  - aggregates.json  (${aggregates.hardest_top10.length} hardest questions)`);
  console.log(`  - full_report.json (${Object.keys(fullReport.all_questions).length} questions, ${fullReport.total_users} users, ${fullReport.total_sessions} sessions)`);
  console.log(`  - report.md`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
