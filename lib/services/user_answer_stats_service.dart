import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_result.dart';

/// 문항별 누적 답안 통계를 로컬에 저장합니다.
/// 저장 형식: SharedPreferences 키 [_key] → JSON (questionId → {a, c, oc})
///   a  = attempts (총 시도 횟수)
///   c  = correct  (정답 횟수)
///   oc = option_counts (보기별 선택 횟수, 0-based 인덱스)
class AnswerQuestionStat {
  final int questionId;
  int attempts;
  int correct;

  /// 보기별 선택 횟수 (0-based). 문항의 보기 수만큼 길이가 맞춰집니다.
  List<int> optionCounts;

  AnswerQuestionStat({
    required this.questionId,
    this.attempts = 0,
    this.correct = 0,
    List<int>? optionCounts,
  }) : optionCounts = optionCounts ?? [];

  Map<String, dynamic> toJson() => {
        'a': attempts,
        'c': correct,
        'oc': optionCounts,
      };

  factory AnswerQuestionStat.fromJson(int id, Map<String, dynamic> j) {
    return AnswerQuestionStat(
      questionId: id,
      attempts: (j['a'] as num?)?.toInt() ?? 0,
      correct: (j['c'] as num?)?.toInt() ?? 0,
      optionCounts: (j['oc'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
    );
  }

  double get accuracyRate => attempts > 0 ? correct / attempts : 0;
  int get wrongCount => attempts - correct;
}

class OverallStats {
  final int questionsAnswered;
  final int totalAttempts;
  final int totalCorrect;

  const OverallStats({
    required this.questionsAnswered,
    required this.totalAttempts,
    required this.totalCorrect,
  });

  double get accuracyRate =>
      totalAttempts > 0 ? totalCorrect / totalAttempts : 0;
}

class UserAnswerStatsService {
  static const _key = 'user_answer_stats_v1';

  static Future<Map<int, AnswerQuestionStat>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <int, AnswerQuestionStat>{};
      for (final entry in decoded.entries) {
        final id = int.tryParse(entry.key);
        if (id == null) continue;
        result[id] = AnswerQuestionStat.fromJson(
          id,
          entry.value as Map<String, dynamic>,
        );
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveAll(Map<int, AnswerQuestionStat> stats) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, dynamic>{};
    for (final entry in stats.entries) {
      encoded[entry.key.toString()] = entry.value.toJson();
    }
    await prefs.setString(_key, jsonEncode(encoded));
  }

  /// 세션 결과를 문항별 누적 통계에 반영합니다.
  static Future<void> applySessionResults(
    List<SessionResult> results,
  ) async {
    if (results.isEmpty) return;
    final stats = await loadAll();

    for (final r in results) {
      final int optionCount = r.question.options.length;
      final stat =
          stats[r.questionId] ?? AnswerQuestionStat(questionId: r.questionId);

      // 보기 배열 길이를 문항의 보기 수에 맞춥니다.
      while (stat.optionCounts.length < optionCount) {
        stat.optionCounts.add(0);
      }

      stat.attempts++;
      if (r.isCorrect) stat.correct++;

      for (final idx in r.selectedIndices) {
        if (idx >= 0 && idx < stat.optionCounts.length) {
          stat.optionCounts[idx]++;
        }
      }

      stats[r.questionId] = stat;
    }

    await _saveAll(stats);
  }

  /// 전체 집계 요약을 반환합니다.
  static Future<OverallStats> getOverallStats() async {
    final all = await loadAll();
    int totalAttempts = 0;
    int totalCorrect = 0;
    for (final s in all.values) {
      totalAttempts += s.attempts;
      totalCorrect += s.correct;
    }
    return OverallStats(
      questionsAnswered: all.length,
      totalAttempts: totalAttempts,
      totalCorrect: totalCorrect,
    );
  }

  /// 정답률이 낮은 문항 순으로 최대 [n]개를 반환합니다.
  /// [minAttempts]회 이상 시도한 문항만 포함합니다.
  static Future<List<AnswerQuestionStat>> getHardestQuestions({
    int n = 10,
    int minAttempts = 2,
  }) async {
    final all = await loadAll();
    final eligible = all.values
        .where((s) => s.attempts >= minAttempts && s.wrongCount > 0)
        .toList();
    eligible.sort((a, b) => a.accuracyRate.compareTo(b.accuracyRate));
    return eligible.take(n).toList();
  }
}
