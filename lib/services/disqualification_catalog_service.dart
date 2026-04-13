import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/disqualification_catalog.dart';

class DisqualificationCatalogService {
  static const _mergedAsset = 'assets/driving_disqualification_merged.json';

  static const _functionTestType = '기능시험';
  static const _roadTestType = '도로주행시험';

  static Future<DisqualificationCatalog?> load() async {
    try {
      final str = await rootBundle.loadString(_mergedAsset);
      final root = jsonDecode(str) as Map<String, dynamic>;
      final tests = root['tests'] as List<dynamic>? ?? [];

      Map<String, dynamic>? functionTest;
      Map<String, dynamic>? roadTest;
      for (final raw in tests) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final type = m['test_type']?.toString() ?? '';
        if (type == _functionTestType) functionTest = m;
        if (type == _roadTestType) roadTest = m;
      }

      if (functionTest == null || roadTest == null) return null;

      final catsRaw = functionTest['categories'] as List<dynamic>? ?? [];
      final drivingCategories = catsRaw
          .map((e) => DrivingDisqualCategory.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();

      final roadRaw =
          roadTest['disqualification_criteria'] as List<dynamic>? ?? [];
      final roadItems = roadRaw
          .map((e) => DisqualCriterion.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();

      final typesRaw =
          roadTest['applicable_license_types'] as List<dynamic>? ?? [];
      final roadApplicableTypes =
          typesRaw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();

      final drivingTitle =
          '${functionTest['test_type'] ?? _functionTestType} 실격기준';
      final roadTitle =
          '${roadTest['test_type'] ?? _roadTestType} 실격기준';

      return DisqualificationCatalog(
        drivingTitle: drivingTitle,
        drivingSource: (functionTest['source'] ?? '').toString(),
        drivingCategories: drivingCategories,
        roadTitle: roadTitle,
        roadSource: (roadTest['source'] ?? '').toString(),
        roadApplicableTypes: roadApplicableTypes,
        roadItems: roadItems,
      );
    } catch (_) {
      return null;
    }
  }
}
