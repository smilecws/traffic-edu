import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/study_card.dart';

/// 학습 토픽 16개 메타데이터.
///
/// 파일명 슬러그와 1:1 매핑된다. id 순서가 곧 학습 화면 노출 순서이며,
/// 손으로 작성된 `assets/study/NN_<slug>.json` 과 이름이 어긋나면 안 된다.
class StudyTopicMeta {
  const StudyTopicMeta({required this.id, required this.slug});
  final int id;
  final String slug;

  String get assetPath => 'assets/study/$slug.json';
}

class StudyCardService {
  StudyCardService._();

  static const List<StudyTopicMeta> topics = [
    StudyTopicMeta(id: 1, slug: '01_speed_and_lane'),
    StudyTopicMeta(id: 2, slug: '02_highway_tunnel_special_env'),
    StudyTopicMeta(id: 3, slug: '03_centerline_lane_road_marking'),
    StudyTopicMeta(id: 4, slug: '04_dui_and_drug_driving'),
    StudyTopicMeta(id: 5, slug: '05_emergency_vehicle_yielding'),
    StudyTopicMeta(id: 6, slug: '06_vulnerable_pedestrian_protection'),
    StudyTopicMeta(id: 7, slug: '07_accident_response_and_liability'),
    StudyTopicMeta(id: 8, slug: '08_large_freight_towing_vehicle'),
    StudyTopicMeta(id: 9, slug: '09_eco_vehicle_autonomous_driving'),
    StudyTopicMeta(id: 10, slug: '10_vehicle_dynamics_inspection_breakdown'),
    StudyTopicMeta(id: 11, slug: '11_parking_safe_habit_defensive'),
    StudyTopicMeta(id: 12, slug: '12_signal_intersection_roundabout'),
    StudyTopicMeta(id: 13, slug: '13_driver_license_and_admin_action'),
    StudyTopicMeta(id: 14, slug: '14_reckless_retaliatory_group_driving'),
    StudyTopicMeta(id: 15, slug: '15_vehicle_definition_and_safety'),
    StudyTopicMeta(id: 16, slug: '16_motorcycle_and_pm'),
  ];

  static final Map<int, StudyTopic> _cache = {};

  static Future<StudyTopic?> loadTopic(int id) async {
    final cached = _cache[id];
    if (cached != null) return cached;
    final meta = topics.where((m) => m.id == id).cast<StudyTopicMeta?>().firstWhere(
          (m) => m != null,
          orElse: () => null,
        );
    if (meta == null) return null;
    try {
      final raw = await rootBundle.loadString(meta.assetPath);
      final topic = StudyTopic.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      _cache[id] = topic;
      return topic;
    } catch (_) {
      return null;
    }
  }

  static void clearCache() {
    _cache.clear();
  }
}
