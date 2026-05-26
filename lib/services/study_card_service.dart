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
    StudyTopicMeta(id: 1, slug: '01_speed_and_lane', title: '속도와 차로 통행'),
    StudyTopicMeta(
      id: 2,
      slug: '02_highway_tunnel_special_env',
      title: '고속도로·터널·특수환경 운전',
    ),
    StudyTopicMeta(
      id: 3,
      slug: '03_centerline_lane_road_marking',
      title: '중앙선·차선·노면 표시',
    ),
    StudyTopicMeta(
      id: 4,
      slug: '04_dui_and_drug_driving',
      title: '음주·약물 운전 규제',
    ),
    StudyTopicMeta(
      id: 5,
      slug: '05_emergency_vehicle_yielding',
      title: '긴급자동차와 길 터주기',
    ),
    StudyTopicMeta(
      id: 6,
      slug: '06_vulnerable_pedestrian_protection',
      title: '교통약자 보호와 보행자 안전',
    ),
    StudyTopicMeta(
      id: 7,
      slug: '07_accident_response_and_liability',
      title: '교통사고 조치와 법적 책임',
    ),
    StudyTopicMeta(
      id: 8,
      slug: '08_large_freight_towing_vehicle',
      title: '대형차·화물차·견인차 운전',
    ),
    StudyTopicMeta(
      id: 9,
      slug: '09_eco_vehicle_autonomous_driving',
      title: '친환경차와 자율주행',
    ),
    StudyTopicMeta(
      id: 10,
      slug: '10_vehicle_dynamics_inspection_breakdown',
      title: '차량 운동특성·점검·고장 대처',
    ),
    StudyTopicMeta(
      id: 11,
      slug: '11_parking_safe_habit_defensive',
      title: '주정차·안전습관·방어운전',
    ),
    StudyTopicMeta(
      id: 12,
      slug: '12_signal_intersection_roundabout',
      title: '신호·교차로·회전교차로',
    ),
    StudyTopicMeta(
      id: 13,
      slug: '13_driver_license_and_admin_action',
      title: '운전면허 제도와 행정처분',
    ),
    StudyTopicMeta(
      id: 14,
      slug: '14_reckless_retaliatory_group_driving',
      title: '난폭운전·보복운전·공동위험행위',
    ),
    StudyTopicMeta(
      id: 15,
      slug: '15_vehicle_definition_and_safety',
      title: '자동차의 정의와 종별 안전수칙',
    ),
    StudyTopicMeta(
      id: 16,
      slug: '16_motorcycle_and_pm',
      title: '이륜차와 개인형 이동장치(PM)',
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
