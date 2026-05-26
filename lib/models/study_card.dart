/// 학습 카드(교육자료) 모델. `assets/study/NN_<slug>.json` 1파일 = 1 토픽.
///
/// 한국어 단일 언어로 작성된다 (다국어는 추후 별도 작업).
///
/// 구조:
///   StudyTopic (1~16)
///     ├ subTopics[3]  (StudySubTopic, marker = "A/B/C" 또는 "1/2/3")
///     │   └ cards[]   (StudyCardItem)
///     └ examAnalysis? (선택, 대표 기출문제 분석 — 토픽별로 점진 채움)
library;

class StudyTopic {
  const StudyTopic({
    required this.id,
    required this.title,
    required this.subTopics,
    this.examAnalysis,
  });

  final int id;
  final String title;
  final List<StudySubTopic> subTopics;
  final ExamAnalysis? examAnalysis;

  int get totalCards =>
      subTopics.fold(0, (sum, st) => sum + st.cards.length);

  factory StudyTopic.fromJson(Map<String, dynamic> j) {
    final examRaw = j['exam_analysis'];
    return StudyTopic(
      id: (j['id'] as num).toInt(),
      title: j['title'] as String,
      subTopics: (j['sub_topics'] as List)
          .map((e) =>
              StudySubTopic.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      examAnalysis: examRaw is Map
          ? ExamAnalysis.fromJson(Map<String, dynamic>.from(examRaw))
          : null,
    );
  }
}

class StudySubTopic {
  const StudySubTopic({
    required this.marker,
    required this.title,
    required this.cards,
  });

  final String marker;
  final String title;
  final List<StudyCardItem> cards;

  factory StudySubTopic.fromJson(Map<String, dynamic> j) {
    return StudySubTopic(
      marker: j['marker'].toString(),
      title: j['title'] as String,
      cards: (j['cards'] as List)
          .map((e) =>
              StudyCardItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class StudyCardItem {
  const StudyCardItem({
    required this.number,
    required this.title,
    required this.badge,
    required this.label,
    required this.subtitle,
    required this.body,
    required this.keyPoints,
    required this.comparisonTable,
    required this.tags,
  });

  final int number;
  final String title;
  final StudyBadge badge;
  final String label;
  final String subtitle;
  final String body;
  final List<String> keyPoints;
  final ComparisonTable comparisonTable;
  final List<String> tags;

  factory StudyCardItem.fromJson(Map<String, dynamic> j) {
    return StudyCardItem(
      number: (j['number'] as num).toInt(),
      title: j['title'] as String,
      badge: StudyBadge.fromJson(Map<String, dynamic>.from(j['badge'] as Map)),
      label: j['label'] as String,
      subtitle: (j['subtitle'] ?? '').toString(),
      body: j['body'] as String,
      keyPoints: (j['key_points'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      comparisonTable: ComparisonTable.fromJson(
        Map<String, dynamic>.from(j['comparison_table'] as Map),
      ),
      tags: (j['tags'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class StudyBadge {
  const StudyBadge({required this.number, required this.code});

  final String number;
  final String code;

  factory StudyBadge.fromJson(Map<String, dynamic> j) {
    return StudyBadge(
      number: j['number'].toString(),
      code: j['code'] as String,
    );
  }
}

class ComparisonTable {
  const ComparisonTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  bool get isEmpty => headers.isEmpty || rows.isEmpty;

  factory ComparisonTable.fromJson(Map<String, dynamic> j) {
    return ComparisonTable(
      headers: (j['headers'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      rows: (j['rows'] as List? ?? const [])
          .map((r) => (r as List).map((e) => e.toString()).toList())
          .toList(),
    );
  }
}

/// 토픽 단위의 "대표 기출문제 분석" 섹션.
/// 학습 카드 본문과 별개로, 시험에 자주 나오는 포인트와 암기 공식을 따로 정리.
class ExamAnalysis {
  const ExamAnalysis({
    required this.relatedQuestions,
    required this.keyPoints,
    required this.mnemonics,
  });

  /// 예: "학과시험 문제은행 997번 등 유사 문항"
  final String relatedQuestions;
  final List<ExamAnalysisPoint> keyPoints;

  /// 짧은 한 줄 공식들. 예: "비 오면 → 20% 감속!"
  final List<String> mnemonics;

  factory ExamAnalysis.fromJson(Map<String, dynamic> j) {
    return ExamAnalysis(
      relatedQuestions: (j['related_questions'] ?? '').toString(),
      keyPoints: (j['key_points'] as List? ?? const [])
          .map((e) => ExamAnalysisPoint.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      mnemonics: (j['mnemonics'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class ExamAnalysisPoint {
  const ExamAnalysisPoint({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  factory ExamAnalysisPoint.fromJson(Map<String, dynamic> j) {
    return ExamAnalysisPoint(
      title: (j['title'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
    );
  }
}
