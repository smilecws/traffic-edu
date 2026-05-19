import 'package:shared_preferences/shared_preferences.dart';

/// 익명 학습 통계의 서버 수집 여부를 사용자가 켜고 끌 수 있게 합니다.
/// 기본값은 true(수집 허용)이며 거부 시 [GlobalAnswerStatsService] 는 no-op.
class GlobalStatsConsentService {
  GlobalStatsConsentService._();

  static const _key = 'global_stats_consent_v1';

  /// 저장된 값이 없으면 true(기본 허용).
  static Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_key)) return true;
    return prefs.getBool(_key) ?? true;
  }

  static Future<void> save(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, granted);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
