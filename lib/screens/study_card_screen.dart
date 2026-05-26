import 'package:flutter/material.dart';

import '../models/study_card.dart';
import '../services/study_card_service.dart';
import '../theme/app_theme_colors.dart';
import '../utils/topic_palette.dart';
import '../widgets/glass/glass_app_bar.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/gradient_icon_badge.dart';

/// 학습 토픽 상세 화면.
///
/// `assets/study/NN_<slug>.json` 의 토픽 한 개를 로드해, 세부 주제(A/B/C 또는
/// 1/2/3) 아코디언과 그 안의 가로 스와이프 카드뉴스(카드 5장), 그리고 하단의
/// "시험 출제 분석" 섹션을 보여줍니다.
class StudyCardScreen extends StatefulWidget {
  const StudyCardScreen({super.key, required this.topicId});

  final int topicId;

  @override
  State<StudyCardScreen> createState() => _StudyCardScreenState();
}

class _StudyCardScreenState extends State<StudyCardScreen> {
  bool _loading = true;
  StudyTopic? _topic;
  String? _openSubTopicMarker;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final topic = await StudyCardService.loadTopic(widget.topicId);
    if (!mounted) return;
    setState(() {
      _topic = topic;
      _loading = false;
      _openSubTopicMarker = topic?.subTopics.first.marker;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    if (_loading) {
      return GlassScaffold(
        appBar: const GlassAppBar(title: SizedBox.shrink()),
        body: Center(
          child: CircularProgressIndicator(
            color: ac.gradientIndigo[0],
            strokeWidth: 3,
          ),
        ),
      );
    }

    final topic = _topic;
    if (topic == null) {
      return GlassScaffold(
        appBar: const GlassAppBar(title: SizedBox.shrink()),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '학습 자료를 불러오지 못했습니다.',
              style: TextStyle(color: ac.textSecondary, fontSize: 14),
            ),
          ),
        ),
      );
    }

    final gradient = topicGradient(context, topic.id);
    final accent = gradient[0];

    return GlassScaffold(
      appBar: GlassAppBar(title: Text(topic.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          for (final st in topic.subTopics) ...[
            _SubTopicTile(
              subTopic: st,
              gradient: gradient,
              isOpen: _openSubTopicMarker == st.marker,
              onToggle: () => setState(() {
                _openSubTopicMarker =
                    _openSubTopicMarker == st.marker ? null : st.marker;
              }),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 10),
          _ExamAnalysisCard(analysis: topic.examAnalysis, accent: accent),
        ],
      ),
    );
  }
}

class _SubTopicTile extends StatelessWidget {
  const _SubTopicTile({
    required this.subTopic,
    required this.gradient,
    required this.isOpen,
    required this.onToggle,
  });

  final StudySubTopic subTopic;
  final List<Color> gradient;
  final bool isOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final accent = gradient[0];
    return GlassCard(
      borderRadius: 18,
      padding: EdgeInsets.zero,
      borderColor: isOpen ? accent.withValues(alpha: 0.45) : null,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  GradientIconBadge(
                    gradient: gradient,
                    size: 44,
                    child: Text(
                      subTopic.marker,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      subTopic.title,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ac.textPrimary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: ac.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isOpen
                ? _CardCarousel(cards: subTopic.cards, accent: accent)
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}

class _CardCarousel extends StatefulWidget {
  const _CardCarousel({required this.cards, required this.accent});

  final List<StudyCardItem> cards;
  final Color accent;

  @override
  State<_CardCarousel> createState() => _CardCarouselState();
}

class _CardCarouselState extends State<_CardCarousel> {
  late final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final total = widget.cards.length;
    if (total == 0) return;
    final next = (_index + delta + total) % total;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _jumpTo(int i) {
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    if (cards.isEmpty) return const SizedBox.shrink();
    final accent = widget.accent;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Column(
        children: [
          Container(
            height: 540,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: PageView.builder(
              controller: _controller,
              itemCount: cards.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) =>
                  _CardView(card: cards[i], accent: accent),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _RoundButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => _go(-1),
                background: Colors.white,
                foreground: context.appColors.textPrimary,
              ),
              const Spacer(),
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _jumpTo(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _index ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? accent
                          : accent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              _RoundButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => _go(1),
                background: accent,
                foreground: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: foreground),
        ),
      ),
    );
  }
}

class _CardView extends StatelessWidget {
  const _CardView({required this.card, required this.accent});

  final StudyCardItem card;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${card.badge.number} · ${card.badge.code}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    card.label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              card.title,
              style: TextStyle(
                fontSize: 17,
                height: 1.3,
                fontWeight: FontWeight.w800,
                color: ac.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              card.subtitle,
              style: TextStyle(
                fontSize: 12.5,
                color: ac.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              card.body,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: ac.textPrimary,
              ),
            ),
            if (card.keyPoints.isNotEmpty) ...[
              const SizedBox(height: 12),
              _KeyPointsBox(points: card.keyPoints, accent: accent),
            ],
            const SizedBox(height: 12),
            _ComparisonTableView(table: card.comparisonTable, accent: accent),
            if (card.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in card.tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ac.chipBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ac.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KeyPointsBox extends StatelessWidget {
  const _KeyPointsBox({required this.points, required this.accent});

  final List<String> points;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '핵심 포인트',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: accent,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < points.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    points[i],
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: ac.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonTableView extends StatelessWidget {
  const _ComparisonTableView({required this.table, required this.accent});

  final ComparisonTable table;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    if (table.headers.isEmpty || table.rows.isEmpty) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            accent.withValues(alpha: 0.14),
          ),
          headingTextStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: accent,
          ),
          dataTextStyle: TextStyle(
            fontSize: 12,
            color: ac.textPrimary,
            height: 1.4,
          ),
          dividerThickness: 0.6,
          columnSpacing: 18,
          horizontalMargin: 12,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 64,
          columns: [
            for (final h in table.headers) DataColumn(label: Text(h)),
          ],
          rows: [
            for (final row in table.rows)
              DataRow(cells: [
                for (var i = 0; i < table.headers.length; i++)
                  DataCell(Text(i < row.length ? row[i] : '')),
              ]),
          ],
        ),
      ),
    );
  }
}

class _ExamAnalysisCard extends StatelessWidget {
  const _ExamAnalysisCard({required this.analysis, required this.accent});

  final ExamAnalysis analysis;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    if (analysis.relatedQuestions.isEmpty && analysis.keyContent.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ac.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ac.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: accent, size: 18),
              const SizedBox(width: 6),
              Text(
                '시험 출제 분석',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: ac.textPrimary,
                ),
              ),
            ],
          ),
          if (analysis.relatedQuestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                analysis.relatedQuestions,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ],
          if (analysis.keyContent.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < analysis.keyContent.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      analysis.keyContent[i],
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.55,
                        color: ac.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
