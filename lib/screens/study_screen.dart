import 'package:flutter/material.dart';

import '../services/study_card_service.dart';
import '../theme/app_theme_colors.dart';
import '../utils/topic_palette.dart';
import '../widgets/glass/glass_app_bar.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/gradient_icon_badge.dart';
import 'study_card_screen.dart';

/// 학습하기 랜딩. 16개 학습 토픽을 리스트로 보여주고, 탭하면 해당
/// 토픽의 학습 카드 화면([StudyCardScreen]) 으로 이동합니다.
///
/// 리스트는 [StudyCardService.topics] 의 메타(id/title)만 사용해 즉시 그리고,
/// JSON 본문은 상세 화면 진입 시점에 해당 1개만 로드한다.
class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return GlassScaffold(
      appBar: const GlassAppBar(title: Text('학습하기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            '주제별 학습 카드로 핵심 개념과 시험 출제 포인트를 정리해 보세요.',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              height: 1.5,
              color: ac.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...StudyCardService.topics.map((meta) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StudyTopicTile(
                meta: meta,
                gradient: topicGradient(context, meta.id),
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => StudyCardScreen(topicId: meta.id),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StudyTopicTile extends StatelessWidget {
  const _StudyTopicTile({
    required this.meta,
    required this.gradient,
    required this.onTap,
  });

  final StudyTopicMeta meta;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return GlassCard(
      borderRadius: 16,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              GradientIconBadge(
                gradient: gradient,
                size: 44,
                child: Text(
                  meta.id.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  meta.title,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ac.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ac.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
