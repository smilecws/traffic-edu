import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/study_card.dart';

/// 학습 토픽 16개 메타데이터.
///
/// 파일명 슬러그와 1:1 매핑된다. id 순서가 곧 학습 화면 노출 순서이며,
/// 손으로 작성된 `assets/study/NN_<slug>.json` 과 이름이 어긋나면 안 된다.
/// title 은 JSON 의 `title` 필드와 동기화 상태를 유지해야 한다 — 리스트
/// 화면에서 JSON 을 읽지 않고 곧바로 그리기 위해 미리 박아둔다.
class StudyTopicMeta {
  const StudyTopicMeta({
    required this.id,
    required this.slug,
    required this.title,
  });

  final int id;
  final String slug;
  final String title;

  String get assetPath => 'assets/study/$slug.json';
}

class StudyCardService {
  StudyCardService._();

  static const List<StudyTopicMeta> topics = [
    StudyTopicMeta(id: 1, slug: '01_speed_and_lane', title: '속도, 앞지르기, 차로'),
    StudyTopicMeta(
      id: 2,
      slug: '02_highway_tunnel_special_env',
      title: '도로 종류별 안전운전',
    ),
    StudyTopicMeta(
      id: 3,
      slug: '03_centerline_lane_road_marking',
      title: '도로 구조의 이해',
    ),
    StudyTopicMeta(
      id: 4,
      slug: '04_dui_and_drug_driving',
      title: '음주운전, 약물·마약운전',
    ),
    StudyTopicMeta(
      id: 5,
      slug: '05_emergency_vehicle_yielding',
      title: '긴급자동차와 길터주기',
    ),
    StudyTopicMeta(
      id: 6,
      slug: '06_vulnerable_pedestrian_protection',
      title: '교통약자 및 보호구역의 이해',
    ),
    StudyTopicMeta(
      id: 7,
      slug: '07_accident_response_and_liability',
      title: '교통사고의 이해',
    ),
    StudyTopicMeta(
      id: 8,
      slug: '08_large_freight_towing_vehicle',
      title: '차량 종류별 안전운전',
    ),
    StudyTopicMeta(
      id: 9,
      slug: '09_eco_vehicle_autonomous_driving',
      title: '친환경 운전과 자율주행',
    ),
    StudyTopicMeta(
      id: 10,
      slug: '10_vehicle_dynamics_inspection_breakdown',
      title: '차량의 운동특성과 점검',
    ),
    StudyTopicMeta(
      id: 11,
      slug: '11_parking_safe_habit_defensive',
      title: '교통안전수칙',
    ),
    StudyTopicMeta(
      id: 12,
      slug: '12_signal_intersection_roundabout',
      title: '신호와 안전표지 교차로 통행방법',
    ),
    StudyTopicMeta(
      id: 13,
      slug: '13_driver_license_and_admin_action',
      title: '운전면허제도',
    ),
    StudyTopicMeta(
      id: 14,
      slug: '14_reckless_retaliatory_group_driving',
      title: '난폭운전·보복운전·공동위험행위',
    ),
    StudyTopicMeta(
      id: 15,
      slug: '15_vehicle_definition_and_safety',
      title: '자동차 등의 이해(사륜자동차)',
    ),
    StudyTopicMeta(
      id: 16,
      slug: '16_motorcycle_and_pm',
      title: '자동차등의 이해 (이륜자동차)',
    ),
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
