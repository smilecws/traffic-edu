import 'package:flutter/material.dart';

import '../models/study_card.dart';
import '../services/study_card_service.dart';
import '../theme/app_theme_colors.dart';
import 'study_card_screen.dart';

/// 학습하기 랜딩. 16개 학습 토픽을 리스트로 보여주고, 탭하면 해당
/// 토픽의 학습 카드 화면([StudyCardScreen]) 으로 이동합니다.
class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  List<StudyTopic> _topics = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = <StudyTopic>[];
    for (final meta in StudyCardService.topics) {
      final topic = await StudyCardService.loadTopic(meta.id);
      if (topic != null) loaded.add(topic);
    }
    if (!mounted) return;
    setState(() {
      _topics = loaded;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          '학습하기',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: colors.primary,
                strokeWidth: 3,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  '주제별 학습 카드로 핵심 개념과 시험 출제 포인트를 정리해 보세요.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ..._topics.map((topic) {
                  final accent = _accentFor(topic.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _StudyTopicTile(
                      topic: topic,
                      accent: accent,
                      onTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => StudyCardScreen(topicId: topic.id),
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

/// 토픽 id 별 강조색. 16개를 4계열로 순환.
Color _accentFor(int id) {
  const palette = <Color>[
    Color(0xFF22C55E), // green
    Color(0xFF3B82F6), // blue
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // red
    Color(0xFF8B5CF6), // violet
    Color(0xFF06B6D4), // cyan
    Color(0xFFEC4899), // pink
    Color(0xFF14B8A6), // teal
  ];
  return palette[(id - 1) % palette.length];
}

class _StudyTopicTile extends StatelessWidget {
  const _StudyTopicTile({
    required this.topic,
    required this.accent,
    required this.onTap,
  });

  final StudyTopic topic;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Material(
      color: ac.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ac.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  topic.id.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ac.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${topic.subTopics.length}개 세부 주제 · 카드 ${topic.totalCards}장',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: ac.textSecondary,
                      ),
                    ),
                  ],
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
