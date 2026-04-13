import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/mock_exam_history_entry.dart';

class MockExamHistoryService {
  static const _key = 'mock_exam_history_json_v1';
  static const _maxEntries = 80;

  static Future<List<MockExamHistoryEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final out = <MockExamHistoryEntry>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final e = MockExamHistoryEntry.tryParse(
          Map<String, dynamic>.from(item),
        );
        if (e != null) out.add(e);
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  static Future<MockExamHistoryEntry?> latestEntry() async {
    final list = await loadEntries();
    return list.isEmpty ? null : list.first;
  }

  static Future<void> addRecord(MockExamHistoryEntry entry) async {
    final all = await loadEntries();
    final next = [entry, ...all];
    if (next.length > _maxEntries) {
      next.removeRange(_maxEntries, next.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }
}
