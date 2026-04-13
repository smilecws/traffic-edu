import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 저장된 앱 표시 언어 (ko / en / zh / vi)
class LocaleService {
  LocaleService._();

  static const _key = 'app_locale_language_code';

  static const supportedLocales = <Locale>[
    Locale('ko'),
    Locale('en'),
    Locale('zh'),
    Locale('vi'),
  ];

  static bool isSupported(Locale locale) {
    return supportedLocales.any((l) => l.languageCode == locale.languageCode);
  }

  static Future<Locale> loadPreferredLocale() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(_key);
    if (code == null || code.isEmpty) return const Locale('ko');
    final loc = Locale(code);
    return isSupported(loc) ? loc : const Locale('ko');
  }

  static Future<void> saveLanguageCode(String languageCode) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, languageCode);
  }

  /// UI 로케일 코드 → `assets/` 문제 은행 JSON (`questions_kor.json` 등)
  static String questionsBankAssetPath(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'assets/questions_eng.json';
      case 'zh':
        return 'assets/questions_chi.json';
      case 'vi':
        return 'assets/questions_vi.json';
      case 'ko':
      default:
        return 'assets/questions_kor.json';
    }
  }
}
