import 'mock_exam_license_kind.dart';

class MockExamHistoryEntry {
  const MockExamHistoryEntry({
    required this.atMillis,
    required this.licenseKind,
    required this.score,
    required this.total,
    this.wrongQuestionIds = const [],
  });

  final int atMillis;
  final MockExamLicenseKind licenseKind;
  final int score;
  final int total;

  /// 이 모의고사에서 틀린 문제 ID 목록.
  /// 구버전 기록(wrong_ids 키 없음)에서는 빈 리스트로 파싱됩니다.
  final List<int> wrongQuestionIds;

  DateTime get at => DateTime.fromMillisecondsSinceEpoch(atMillis);

  int get scaledScoreOutOf100 =>
      total <= 0 ? 0 : ((score * 100) / total).round();

  bool get passed =>
      scaledScoreOutOf100 >= licenseKind.passScoreMinOutOf100;

  Map<String, dynamic> toJson() => {
        'at': atMillis,
        'kind': licenseKind.name,
        'score': score,
        'total': total,
        if (wrongQuestionIds.isNotEmpty) 'wrong_ids': wrongQuestionIds,
      };

  static MockExamHistoryEntry? tryParse(Map<String, dynamic> j) {
    try {
      final at = j['at'];
      final kindStr = j['kind'];
      final score = j['score'];
      final total = j['total'];
      if (at is! int || kindStr is! String || score is! int || total is! int) {
        return null;
      }
      final kind = MockExamLicenseKind.values.asNameMap()[kindStr];
      if (kind == null) return null;
      final wrongIds = (j['wrong_ids'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[];
      return MockExamHistoryEntry(
        atMillis: at,
        licenseKind: kind,
        score: score,
        total: total,
        wrongQuestionIds: wrongIds,
      );
    } catch (_) {
      return null;
    }
  }
}
