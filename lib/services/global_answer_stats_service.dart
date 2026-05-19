import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/session_result.dart';
import 'global_stats_consent_service.dart';

/// Firestore 한 문서(`question_stats/{questionId}`) 에 대응되는 익명 집계 통계.
class GlobalQuestionStat {
  final int questionId;
  final int attempts;
  final int correct;

  /// 보기별 선택 횟수. key = 0-based 인덱스.
  final Map<int, int> optionCounts;

  const GlobalQuestionStat({
    required this.questionId,
    required this.attempts,
    required this.correct,
    required this.optionCounts,
  });

  double get accuracyRate => attempts > 0 ? correct / attempts : 0;
  int get wrongCount => attempts - correct;
}

/// 전체 사용자 익명 집계 통계 서비스.
///
/// - 쓰기: 세션 종료 시 [applySessionResults] 1회. 문항별 `attempts`/`correct`/
///   `option_counts.{idx}` 를 +1 씩 증가. 동의 거부·익명 로그인 실패·미지원
///   플랫폼이면 모두 no-op (throw 하지 않음).
/// - 읽기: [loadAllStats] 가 1000문서 전체를 한 번에 받아 5분 TTL 메모리 캐시.
///   StatsScreen 이 진입할 때마다 네트워크를 다시 두드리지 않는다.
class GlobalAnswerStatsService {
  GlobalAnswerStatsService._();

  static const _collection = 'question_stats';
  static const Duration _cacheTtl = Duration(minutes: 5);

  static Map<int, GlobalQuestionStat>? _cache;
  static DateTime? _cacheLoadedAt;
  static Future<Map<int, GlobalQuestionStat>>? _inFlight;

  /// Web/Android/iOS 에서만 true. Windows/macOS/Linux 데스크톱은 cloud_firestore
  /// 미지원이므로 false.
  static bool get isSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 쓰기
  // ─────────────────────────────────────────────────────────────────────────

  /// 세션 결과를 Firestore 에 batch increment 로 반영한다.
  /// 실패해도 throw 하지 않는다(로컬 저장 흐름을 막지 않기 위해).
  static Future<void> applySessionResults(List<SessionResult> results) async {
    if (!isSupported || results.isEmpty) return;

    final consent = await GlobalStatsConsentService.load();
    if (!consent) return;

    if (FirebaseAuth.instance.currentUser == null) {
      // main.dart 에서 익명 로그인이 완료되지 못한 경우 — 한 번 더 시도.
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (_) {
        return;
      }
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      for (final r in results) {
        final ref = firestore.collection(_collection).doc(r.questionId.toString());
        final updates = <String, Object>{
          'attempts': FieldValue.increment(1),
          'correct': FieldValue.increment(r.isCorrect ? 1 : 0),
          'last_updated_at': FieldValue.serverTimestamp(),
        };
        for (final idx in r.selectedIndices) {
          updates['option_counts.$idx'] = FieldValue.increment(1);
        }
        batch.set(ref, updates, SetOptions(merge: true));
      }
      await batch.commit();

      // 새 카운트가 반영됐으니 캐시 무효화. (다음 read 시 재로딩)
      _invalidateCache();
    } catch (e) {
      // 네트워크/권한 오류는 무시. Firestore 가 자체 오프라인 큐를 가짐.
      debugPrint('GlobalAnswerStatsService.applySessionResults failed: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 읽기
  // ─────────────────────────────────────────────────────────────────────────

  /// 전체 통계 맵을 반환한다. 5분 캐시.
  /// 미지원 플랫폼이면 빈 맵.
  static Future<Map<int, GlobalQuestionStat>> loadAllStats({
    bool forceRefresh = false,
  }) async {
    if (!isSupported) return const {};

    if (!forceRefresh && _cache != null && _cacheLoadedAt != null) {
      if (DateTime.now().difference(_cacheLoadedAt!) < _cacheTtl) {
        return _cache!;
      }
    }
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchAll();
    _inFlight = future;
    try {
      final result = await future;
      _cache = result;
      _cacheLoadedAt = DateTime.now();
      return result;
    } finally {
      _inFlight = null;
    }
  }

  /// 단일 문항 통계. 캐시 우선, 없으면 단일 문서 fetch.
  static Future<GlobalQuestionStat?> loadStat(int questionId) async {
    if (!isSupported) return null;

    final cache = _cache;
    if (cache != null && cache.containsKey(questionId)) {
      return cache[questionId];
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(questionId.toString())
          .get();
      if (!snap.exists) return null;
      return _parseDoc(questionId, snap.data() ?? const {});
    } catch (e) {
      debugPrint('GlobalAnswerStatsService.loadStat failed: $e');
      return null;
    }
  }

  static Future<Map<int, GlobalQuestionStat>> _fetchAll() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection(_collection).get();
      final result = <int, GlobalQuestionStat>{};
      for (final doc in snap.docs) {
        final id = int.tryParse(doc.id);
        if (id == null) continue;
        result[id] = _parseDoc(id, doc.data());
      }
      return result;
    } catch (e) {
      debugPrint('GlobalAnswerStatsService._fetchAll failed: $e');
      return const {};
    }
  }

  static GlobalQuestionStat _parseDoc(int id, Map<String, dynamic> data) {
    final attempts = (data['attempts'] as num?)?.toInt() ?? 0;
    final correct = (data['correct'] as num?)?.toInt() ?? 0;
    final rawCounts = data['option_counts'];
    final optionCounts = <int, int>{};
    if (rawCounts is Map) {
      rawCounts.forEach((key, value) {
        final idx = int.tryParse(key.toString());
        if (idx != null && value is num) {
          optionCounts[idx] = value.toInt();
        }
      });
    }
    return GlobalQuestionStat(
      questionId: id,
      attempts: attempts,
      correct: correct,
      optionCounts: optionCounts,
    );
  }

  static void _invalidateCache() {
    _cache = null;
    _cacheLoadedAt = null;
  }

  @visibleForTesting
  static void debugReset() => _invalidateCache();
}
