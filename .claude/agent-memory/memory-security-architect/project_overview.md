---
name: Project Overview
description: Korean driver license quiz app structure, data storage, and feature status
type: project
---

Korean driver license exam practice app (운전면허 학과시험 1000제), built with Flutter.

**Why:** User wants to add comprehensive per-question answer statistics.
**How to apply:** Any new statistics service should follow the existing static-method service pattern and use SharedPreferences for local storage.

## Storage
- Local: SharedPreferences (all current user data)
- Remote: Firebase Firestore planned (question_stats_service.dart does NOT yet exist despite being referenced in prior conversation context)

## Quiz Modes
- Practice mode (showTimerAndScore: false) — answer revealed immediately per question
- Mock exam mode (showTimerAndScore: true) — 40-min timer, answers revealed at results screen only

## Existing Services (all static-method classes, SharedPreferences-backed)
- AttemptedQuestionsService — stores Set<int> of question IDs ever attempted
- WrongNoteService — stores Set<int> of current wrong question IDs (toggled: wrong=add, correct=remove)
- FavoriteQuestionsService — stores Set<int> of starred question IDs
- MockExamHistoryService — stores last 80 mock exam entries (JSON list, score/total/licenseKind/timestamp)
- QuestionService — asset JSON loader with in-memory cache; supports ko/en/zh/vi locale

## Result Data Shape (passed through app as List<Map<String, dynamic>>)
Each result map contains: questionId (int), question (Question), selected (int | Set<int> | null), isCorrect (bool)

## What is MISSING for full statistics
- Per-question attempt count (how many times each question was answered)
- Per-question wrong count (how many times each question was answered wrong)
- Selected option tracking (which wrong option was chosen — never stored)
- Session-level metadata: mode (practice/mock/category), timestamp, duration
- Category-level aggregate stats
- question_stats_service.dart does not exist yet
