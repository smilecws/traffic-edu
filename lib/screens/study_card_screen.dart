import 'package:flutter/material.dart';

import '../models/study_card.dart';
import '../services/study_card_service.dart';
import '../theme/app_theme_colors.dart';
import '../utils/korean_wrap.dart';
import '../utils/topic_palette.dart';
import '../widgets/glass/glass_app_bar.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/glass/glass_scaffold.dart';
import '../widgets/glass/gradient_icon_badge.dart';

/// 학습 토픽 상세 화면.
///
/// `assets/study/NN_<slug>.json` 의 토픽 한 개를 로드해, 세부 주제(A/B/C 또는
/// 1/2/3) 아코디언과 그 안의 가로 스와이프 카드뉴스(카드 5장)를 보여줍니다.
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

    // 선택된 서브토픽은 맨 위로 끌어올리고, 나머지는 원래 순서를 유지해 그 아래에 둔다.
    final orderedSubTopics = _openSubTopicMarker == null
        ? topic.subTopics
        : [
            ...topic.subTopics
                .where((st) => st.marker == _openSubTopicMarker),
            ...topic.subTopics
                .where((st) => st.marker != _openSubTopicMarker),
          ];

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(topic.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: '홈으로',
            onPressed: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          children: [
            for (var i = 0; i < orderedSubTopics.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              // 선택된 타일은 남은 세로 공간을 모두 차지하고, 닫힌 타일은 헤더 높이만
              // 차지하므로 항상 화면 안에서 탭할 수 있도록 노출된다.
              if (orderedSubTopics[i].marker == _openSubTopicMarker)
                Expanded(
                  child: _SubTopicTile(
                    key: ValueKey(orderedSubTopics[i].marker),
                    subTopic: orderedSubTopics[i],
                    gradient: gradient,
                    isOpen: true,
                    onToggle: () => setState(() {
                      _openSubTopicMarker = null;
                    }),
                  ),
                )
              else
                _SubTopicTile(
                  key: ValueKey(orderedSubTopics[i].marker),
                  subTopic: orderedSubTopics[i],
                  gradient: gradient,
                  isOpen: false,
                  onToggle: () => setState(() {
                    _openSubTopicMarker = orderedSubTopics[i].marker;
                  }),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubTopicTile extends StatelessWidget {
  const _SubTopicTile({
    super.key,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  GradientIconBadge(
                    gradient: gradient,
                    size: 34,
                    child: Text(
                      subTopic.marker,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
          if (isOpen)
            Expanded(
              child: _CardCarousel(cards: subTopic.cards, accent: accent),
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
          Expanded(
            child: Container(
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
              wrapByEojeol(card.title),
              style: TextStyle(
                fontSize: 17,
                height: 1.3,
                fontWeight: FontWeight.w800,
                color: ac.textPrimary,
              ),
            ),
            if (card.subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                wrapByEojeol(card.subtitle),
                style: TextStyle(
                  fontSize: 12.5,
                  color: ac.textSecondary,
                ),
              ),
            ],
            if (card.keyPoints.isNotEmpty) ...[
              const SizedBox(height: 12),
              _KeyPointsBox(points: card.keyPoints, accent: accent),
            ],
            if (card.body.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                wrapByEojeol(card.body),
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: ac.textPrimary,
                ),
              ),
            ],
            if (card.imageGrid != null) ...[
              const SizedBox(height: 12),
              _ImageGridView(grid: card.imageGrid!, accent: accent),
            ],
            for (final table in card.comparisonTables)
              if (!table.isEmpty) ...[
                const SizedBox(height: 12),
                _ComparisonTableView(table: table, accent: accent),
              ],
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
                    wrapByEojeol(points[i]),
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
    final headerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: accent,
    );
    final cellStyle = TextStyle(
      fontSize: 12,
      color: ac.textPrimary,
      height: 1.4,
    );
    final dividerColor = ac.textPrimary.withValues(alpha: 0.08);

    // DataTable 은 컨텐츠 폭에 맞춰 좁아져 우측 여백이 남고 가로 스크롤이
    // 필요했다. Table + FlexColumnWidth 로 바꿔서 가용 폭을 가득 채운다.
    // 컬럼 폭 규칙: 1번 컬럼은 카테고리/라벨 컬럼인 경우가 많아 짧은 내용에
    // 과도한 폭이 할당되는 문제가 있었다. Intrinsic 폭을 쓰되 등분 폭(1/N)을
    // 상한으로 캡해서, 짧을 때만 줄어들고 길면 기존 균등 분할과 동일하게
    // 동작하도록 한다. 나머지 컬럼은 남은 공간을 동일 flex 로 나눠 갖는다.
    final colCount = table.headers.length;
    final tableWidget = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Table(
        columnWidths: {
          0: MinColumnWidth(
            const IntrinsicColumnWidth(),
            FractionColumnWidth(1 / colCount),
          ),
          for (var i = 1; i < colCount; i++)
            i: const FlexColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder(
          horizontalInside: BorderSide(width: 0.6, color: dividerColor),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
            ),
            children: [
              for (final h in table.headers)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 8),
                  child: Text(
                    wrapByEojeol(h),
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
          for (final row in table.rows)
            TableRow(
              children: [
                for (var i = 0; i < table.headers.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 8),
                    child: Text(
                      wrapByEojeol(i < row.length ? row[i] : ''),
                      style: cellStyle,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
    if (table.title.isEmpty) return tableWidget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(
            wrapByEojeol(table.title),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ),
        tableWidget,
      ],
    );
  }
}

class _ImageGridView extends StatelessWidget {
  const _ImageGridView({required this.grid, required this.accent});

  final ImageGrid grid;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cells = grid.cells;
    if (cells.isEmpty) return const SizedBox.shrink();
    final cols = grid.columns < 1 ? 1 : grid.columns;
    const spacing = 8.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth =
            (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final cell in cells)
              SizedBox(
                width: cellWidth,
                child: _ImageGridCellView(cell: cell, accent: accent),
              ),
          ],
        );
      },
    );
  }
}

class _ImageGridCellView extends StatelessWidget {
  const _ImageGridCellView({required this.cell, required this.accent});

  final ImageGridCell cell;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: ac.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 11,
            child: Image.asset(
              cell.image,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: ac.textSecondary,
                  size: 28,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              border: Border(
                top: BorderSide(color: accent.withValues(alpha: 0.2)),
              ),
            ),
            child: Text(
              cell.caption,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ac.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
