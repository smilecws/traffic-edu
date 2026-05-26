import 'package:flutter/material.dart';

/// 배경 톤 선택용. 기본값은 [GlassBackgroundVariant.vivid] (기존 화려한 톤).
/// 차분한 5가지 대안:
/// - [indigoMist]: 인디고-슬레이트 페이드 + 매우 옅은 인디고 블롭 하나
/// - [softLavender]: 라벤더 단색조, 옅은 보라 블롭
/// - [cleanSlate]: 미니멀 디아고날 그라데이션 (블롭 없음)
/// - [mutedTwilight]: 현재 톤을 그대로 채도만 낮춘 버전
/// - [coolStone]: 슬레이트→인디고 페이드 + 옅은 시안 블롭
enum GlassBackgroundVariant {
  vivid,
  indigoMist,
  softLavender,
  cleanSlate,
  mutedTwilight,
  coolStone,
}

/// 글래스모피즘 배경. 그라데이션 + 흐릿한 원형 장식 위에 [child] 를 표시한다.
/// 톤은 [variant] 로 선택. 기본은 [GlassBackgroundVariant.indigoMist] (차분한 톤).
class GlassBackground extends StatelessWidget {
  const GlassBackground({
    super.key,
    required this.child,
    this.variant = GlassBackgroundVariant.indigoMist,
  });

  final Widget child;
  final GlassBackgroundVariant variant;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case GlassBackgroundVariant.vivid:
        return _vivid(child);
      case GlassBackgroundVariant.indigoMist:
        return _indigoMist(child);
      case GlassBackgroundVariant.softLavender:
        return _softLavender(child);
      case GlassBackgroundVariant.cleanSlate:
        return _cleanSlate(child);
      case GlassBackgroundVariant.mutedTwilight:
        return _mutedTwilight(child);
      case GlassBackgroundVariant.coolStone:
        return _coolStone(child);
    }
  }
}

/// 둥근 그라데이션 블롭 헬퍼.
Widget _blob({
  required double size,
  required Color color,
  required double alpha,
  double? top,
  double? bottom,
  double? left,
  double? right,
  double blur = 80,
  double spread = 20,
}) {
  return Positioned(
    top: top,
    bottom: bottom,
    left: left,
    right: right,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: color.withValues(alpha: alpha),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: alpha),
            blurRadius: blur,
            spreadRadius: spread,
          ),
        ],
      ),
    ),
  );
}

Widget _scaffoldBg({
  required Gradient gradient,
  required List<Widget> blobs,
  required Widget child,
}) {
  return Stack(
    children: [
      Positioned.fill(
        child: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
      ),
      ...blobs,
      Positioned.fill(child: child),
    ],
  );
}

// ── 변형 1: vivid (기존) ──────────────────────────────────────────
Widget _vivid(Widget child) {
  return _scaffoldBg(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFE0E7FF),
        Color(0xFFFAF5FF),
        Color(0xFFFFE4E6),
      ],
    ),
    blobs: [
      _blob(
        size: 192,
        color: const Color(0xFFC084FC),
        alpha: 0.4,
        top: 40,
        left: -40,
      ),
      _blob(
        size: 224,
        color: const Color(0xFFFB7185),
        alpha: 0.3,
        top: 160,
        right: -40,
      ),
      _blob(
        size: 256,
        color: const Color(0xFF22D3EE),
        alpha: 0.3,
        bottom: 80,
        left: 80,
      ),
    ],
    child: child,
  );
}

// ── 변형 2: indigoMist ────────────────────────────────────────────
// 슬레이트→인디고 페이드 + 옅은 인디고 블롭 1개. 가장 차분/미니멀.
Widget _indigoMist(Widget child) {
  return _scaffoldBg(
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFF1F5F9), // slate-100
        Color(0xFFEEF2FF), // indigo-50
      ],
    ),
    blobs: [
      _blob(
        size: 280,
        color: const Color(0xFF6366F1), // indigo-500
        alpha: 0.12,
        top: 60,
        right: -80,
      ),
    ],
    child: child,
  );
}

// ── 변형 3: softLavender ──────────────────────────────────────────
// 라벤더 단색조. 차분하지만 따뜻함 약간 유지.
Widget _softLavender(Widget child) {
  return _scaffoldBg(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFF5F3FF), // violet-50
        Color(0xFFFAFAFA),
        Color(0xFFF3F4F6), // gray-100
      ],
    ),
    blobs: [
      _blob(
        size: 240,
        color: const Color(0xFFA78BFA), // violet-400
        alpha: 0.16,
        top: 80,
        left: -60,
      ),
      _blob(
        size: 200,
        color: const Color(0xFFC4B5FD), // violet-300
        alpha: 0.14,
        bottom: 120,
        right: -40,
      ),
    ],
    child: child,
  );
}

// ── 변형 4: cleanSlate ────────────────────────────────────────────
// 블롭 없음. 가장 깔끔/미니멀. 그라데이션만으로 깊이감.
Widget _cleanSlate(Widget child) {
  return _scaffoldBg(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFF8FAFC), // slate-50
        Color(0xFFE2E8F0), // slate-200
      ],
    ),
    blobs: const [],
    child: child,
  );
}

// ── 변형 5: mutedTwilight ─────────────────────────────────────────
// 기존 톤 유지하면서 채도/투명도만 절반으로 낮춘 안전한 절충안.
Widget _mutedTwilight(Widget child) {
  return _scaffoldBg(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFEEF2FF), // indigo-50
        Color(0xFFFAF5FF), // purple-50
        Color(0xFFFDF2F8), // pink-50
      ],
    ),
    blobs: [
      _blob(
        size: 192,
        color: const Color(0xFFC084FC),
        alpha: 0.18,
        top: 40,
        left: -40,
      ),
      _blob(
        size: 224,
        color: const Color(0xFFFB7185),
        alpha: 0.13,
        top: 160,
        right: -40,
      ),
      _blob(
        size: 256,
        color: const Color(0xFF22D3EE),
        alpha: 0.12,
        bottom: 80,
        left: 80,
      ),
    ],
    child: child,
  );
}

// ── 변형 6: coolStone ─────────────────────────────────────────────
// 슬레이트→인디고 페이드 + 시안 액센트 하나. 차갑고 모던.
Widget _coolStone(Widget child) {
  return _scaffoldBg(
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFF1F5F9), // slate-100
        Color(0xFFE0E7FF), // indigo-100
      ],
    ),
    blobs: [
      _blob(
        size: 260,
        color: const Color(0xFF06B6D4), // cyan-500
        alpha: 0.14,
        bottom: 60,
        left: 40,
      ),
    ],
    child: child,
  );
}
