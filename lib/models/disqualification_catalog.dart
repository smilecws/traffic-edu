class DisqualCriterion {
  const DisqualCriterion({required this.number, required this.text});

  final int number;
  final String text;

  factory DisqualCriterion.fromJson(Map<String, dynamic> j) {
    return DisqualCriterion(
      number: (j['number'] as num).toInt(),
      text: (j['text'] ?? '').toString(),
    );
  }
}

class DrivingDisqualCategory {
  const DrivingDisqualCategory({
    required this.licenseType,
    required this.criteria,
  });

  final String licenseType;
  final List<DisqualCriterion> criteria;

  factory DrivingDisqualCategory.fromJson(Map<String, dynamic> j) {
    final raw = j['disqualification_criteria'] as List<dynamic>? ?? [];
    return DrivingDisqualCategory(
      licenseType: (j['license_type'] ?? '').toString(),
      criteria: raw
          .map((e) => DisqualCriterion.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class DisqualificationCatalog {
  const DisqualificationCatalog({
    required this.drivingTitle,
    required this.drivingSource,
    required this.drivingCategories,
    required this.roadTitle,
    required this.roadSource,
    required this.roadApplicableTypes,
    required this.roadItems,
  });

  final String drivingTitle;
  final String drivingSource;
  final List<DrivingDisqualCategory> drivingCategories;
  final String roadTitle;
  final String roadSource;
  final List<String> roadApplicableTypes;
  final List<DisqualCriterion> roadItems;

  List<String> get allCriteriaTexts {
    final out = <String>[];
    for (final c in drivingCategories) {
      for (final x in c.criteria) {
        final t = x.text.trim();
        if (t.isNotEmpty) out.add(t);
      }
    }
    for (final x in roadItems) {
      final t = x.text.trim();
      if (t.isNotEmpty) out.add(t);
    }
    return out;
  }
}
