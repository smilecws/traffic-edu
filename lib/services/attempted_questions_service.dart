import 'package:shared_preferences/shared_preferences.dart';

import 'preference_id_codec.dart';

/// 한 번이라도 시험 세션에 포함되어 끝까지 진행된 문제 ID (미풀이 판별용)
class AttemptedQuestionsService {
  static const _key = 'attempted_question_ids';

  static Future<Set<int>> loadAttemptedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? const <String>[];
    return decodeIdStringList(list);
  }

  static Future<void> saveAttemptedIds(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final list = ids.map((e) => e.toString()).toList()..sort();
    await prefs.setStringList(_key, list);
  }

  /// 시험 종료 시 해당 세션의 문항을 모두 "풀어봄"으로 표시
  static Future<void> markSessionAttempted(Iterable<int> questionIds) async {
    final ids = await loadAttemptedIds();
    ids.addAll(questionIds);
    await saveAttemptedIds(ids);
  }
}
