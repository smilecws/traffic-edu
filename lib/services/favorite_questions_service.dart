import 'package:shared_preferences/shared_preferences.dart';

import 'preference_id_codec.dart';

class FavoriteQuestionsService {
  static const _key = 'favorite_question_ids';

  static Future<Set<int>> loadFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? const <String>[];
    return decodeIdStringList(list);
  }

  static Future<void> saveFavoriteIds(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final list = ids.map((e) => e.toString()).toList()..sort();
    await prefs.setStringList(_key, list);
  }

  static Future<void> toggle(int questionId) async {
    final ids = await loadFavoriteIds();
    if (ids.contains(questionId)) {
      ids.remove(questionId);
    } else {
      ids.add(questionId);
    }
    await saveFavoriteIds(ids);
  }

  static Future<bool> isFavorite(int questionId) async {
    final ids = await loadFavoriteIds();
    return ids.contains(questionId);
  }
}
