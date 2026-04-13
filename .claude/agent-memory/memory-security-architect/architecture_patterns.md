---
name: Architecture Patterns
description: Service layer conventions, anti-patterns, and data flow found in the quiz app
type: project
---

## Service Layer Convention
All services are pure static-method Dart classes (no instances, no dependency injection).
Pattern: `class FooService { static Future<T> doSomething() async { ... } }`
SharedPreferences is obtained fresh inside each method call — no caching of the prefs instance.

**Why:** Simple, low-ceremony approach appropriate for a single-developer mobile app.
**How to apply:** New services (e.g., QuestionStatsService) should follow the same static pattern for consistency.

## ID Storage Pattern
Question IDs stored as sorted List<String> in SharedPreferences via preference_id_codec.dart.
Codec: `decodeIdStringList(List<String>)` — safe int parsing, returns Set<int>.
Write pattern: `ids.map((e) => e.toString()).toList()..sort()` before setStringList.

## Anti-patterns Identified

### 1. SharedPreferences read-on-every-call
Each service method calls `SharedPreferences.getInstance()` independently.
WrongNoteService.applySessionResults does: loadWrongIds() (1 prefs read) then saveWrongIds() (1 prefs write).
AttemptedQuestionsService.markSessionAttempted does the same.
In _finalizeAndGoToResults(), both are called sequentially — 4 SharedPreferences I/O operations when 2 would suffice with a shared prefs instance.

### 2. result map uses untyped Map<String, dynamic>
The results list `List<Map<String, dynamic>>` passes Question objects (heavy Dart objects) by reference through the map.
This means the entire Question (including imageUris, imageCaptionsByUri) lives in the results list for the full session.
For 40 questions with multiple large base64 imageUris, this is a non-trivial in-memory footprint.

### 3. No selected-option persistence
The 'selected' field in results is (int | Set<int> | null) — a Dart union type using dynamic.
This is correctly checked with `is int` / `is Set<int>` at usage sites but is fragile and not typed.
Critically: which wrong option the user picked is NEVER persisted — only isCorrect (bool) is saved.

### 4. Image bytes cache has O(1) eviction by insertion order (not LRU)
_imageBytesCache in _QuizScreenState uses `_imageBytesCache.keys.first` for eviction.
In Dart, LinkedHashMap (default) preserves insertion order, so this evicts oldest-inserted, not least-recently-used.
For 24-item cap with sequential question viewing this is functionally adequate but not true LRU.

### 5. MockExamHistoryEntry stores no wrong question IDs
The history entry only records: atMillis, licenseKind, score, total.
There is no link from a mock exam session to which questions were answered incorrectly.

### 6. _loadCounts() in WrittenExamMenuScreen performs 5 sequential async calls
loadQuestionCountOnly, loadAttemptedIds, loadFavoriteIds, loadWrongIds, latestEntry — all awaited sequentially.
These are all independent and could run concurrently with Future.wait([...]).

### 7. Disqualification ticker uses Random().nextInt() on every 3.5s tick
Called in setState(), which is fine, but creates a new Random instance each call rather than reusing one.

## Data Flow: Quiz Session End
_finalizeAndGoToResults():
1. Build allResults (all questions, filling unanswered as isCorrect:false)
2. If mockExamLicenseKind != null: MockExamHistoryService.addRecord(...)
3. WrongNoteService.applySessionResults(allResults)
4. AttemptedQuestionsService.markSessionAttempted(all question IDs)
5. Navigate to ResultScreen

The place to inject QuestionStatsService.recordSessionResults(allResults) is step 2.5, after MockExamHistory and before navigation.
