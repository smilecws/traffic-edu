/// 학습 카드(교육자료) 모델. `assets/study/NN_<slug>.json` 1파일 = 1 토픽.
///
/// 한국어 단일 언어로 작성된다 (다국어는 추후 별도 작업).
///
/// 구조:
///   StudyTopic (1~16)
///     └ subTopics[3]  (StudySubTopic, marker = "A/B/C" 또는 "1/2/3")
///         └ cards[]   (StudyCardItem)
library;

class StudyTopic {
  const StudyTopic({
    required this.id,
    required this.title,
    required this.subTopics,
  });

  final int id;
  final String title;
  final List<StudySubTopic> subTopics;

  int get totalCards =>
      subTopics.fold(0, (sum, st) => sum + st.cards.length);

  factory StudyTopic.fromJson(Map<String, dynamic> j) {
    return StudyTopic(
      id: (j['id'] as num).toInt(),
      title: j['title'] as String,
      subTopics: (j['sub_topics'] as List)
          .map((e) =>
              StudySubTopic.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
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
    required this.comparisonTables,
    required this.tags,
  });

  final int number;
  final String title;
  final StudyBadge badge;
  final String label;
  final String subtitle;
  final String body;
  final List<String> keyPoints;
  final List<ComparisonTable> comparisonTables;
  final List<String> tags;

  factory StudyCardItem.fromJson(Map<String, dynamic> j) {
    // 신규 포맷 `comparison_tables`(배열) 우선. 없으면 레거시 단일
    // `comparison_table`(객체) 을 흡수해 길이 1 리스트로 변환한다.
    final List<ComparisonTable> tables;
    final tablesRaw = j['comparison_tables'];
    final singleRaw = j['comparison_table'];
    if (tablesRaw is List) {
      tables = tablesRaw
          .whereType<Map>()
          .map((e) =>
              ComparisonTable.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else if (singleRaw is Map) {
      final t = ComparisonTable.fromJson(
        Map<String, dynamic>.from(singleRaw),
      );
      tables = t.isEmpty ? const [] : [t];
    } else {
      tables = const [];
    }

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
      comparisonTables: tables,
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
