import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_result.dart';
import 'preference_id_codec.dart';

class WrongNoteService {
  static const _key = 'wrong_question_ids';

  static Future<Set<int>> loadWrongIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? const <String>[];
    return decodeIdStringList(list);
  }

  static Future<int> count() async {
    final ids = await loadWrongIds();
    return ids.length;
  }

  static Future<void> saveWrongIds(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final list = ids.map((e) => e.toString()).toList()..sort();
    await prefs.setStringList(_key, list);
  }

  /// 세션 결과를 반영합니다.
  /// - 틀린 문제: 오답 목록에 추가
  /// - 맞힌 문제: 오답 목록에서 제거
  static Future<void> applySessionResults(
    List<SessionResult> results,
  ) async {
    final ids = await loadWrongIds();
    for (final r in results) {
      if (r.isCorrect) {
        ids.remove(r.questionId);
      } else {
        ids.add(r.questionId);
      }
    }
    await saveWrongIds(ids);
  }
}
