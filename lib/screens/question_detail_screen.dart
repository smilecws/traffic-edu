import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/question.dart';
import '../services/global_answer_stats_service.dart';
import '../services/user_answer_stats_service.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/glass/glass_app_bar.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/glass/glass_scaffold.dart';
import 'quiz_screen.dart';

/// "내 정답률 vs 전체 사용자 정답률" + 보기별 선택 분포 를 보여주는 화면.
/// StatsScreen Top10 또는 ResultScreen 오답 카드 탭 시 진입.
class QuestionDetailScreen extends StatefulWidget {
  const QuestionDetailScreen({super.key, required this.question});

  final Question question;

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  bool _loading = true;
  AnswerQuestionStat? _myStat;
  GlobalQuestionStat? _globalStat;
  bool _globalLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      UserAnswerStatsService.loadAll(),
      GlobalAnswerStatsService.isSupported
          ? GlobalAnswerStatsService.loadStat(widget.question.id)
          : Future<GlobalQuestionStat?>.value(null),
    ]);
    if (!mounted) return;
    final myAll = results[0] as Map<int, AnswerQuestionStat>;
    final global = results[1] as GlobalQuestionStat?;
    setState(() {
      _myStat = myAll[widget.question.id];
      _globalStat = global;
      _globalLoadFailed =
          GlobalAnswerStatsService.isSupported && global == null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ac = context.appColors;

    return GlassScaffold(
      appBar: GlassAppBar(title: Text(l10n.qdetailTitle)),
      body: _loading
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _QuestionBodyCard(question: widget.question),
                  const SizedBox(height: 16),
                  _AccuracyCompareCard(
                    l10n: l10n,
                    myStat: _myStat,
                    globalStat: _globalStat,
                    globalSupported: GlobalAnswerStatsService.isSupported,
                    loadFailed: _globalLoadFailed,
                  ),
                  if (_globalStat != null && _globalStat!.attempts > 0) ...[
                    const SizedBox(height: 16),
                    _OptionDistributionCard(
                      l10n: l10n,
                      question: widget.question,
                      globalStat: _globalStat!,
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: ac.primary,
                      foregroundColor: ac.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      l10n.qdetailRetryButton,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _retry() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: [widget.question],
          title: 'Q.${widget.question.id}',
          showTimerAndScore: false,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 문제 본문 카드
// ─────────────────────────────────────────────────────────────────────────────

class _QuestionBodyCard extends StatelessWidget {
  const _QuestionBodyCard({required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final correctSet = question.correctIndexSet;
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q.${question.id}',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ac.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            question.question,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: ac.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < question.options.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: correctSet.contains(i)
                          ? ac.successBg
                          : ac.chipBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: correctSet.contains(i)
                            ? ac.success
                            : ac.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      question.options[i],
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: ac.textPrimary,
                        fontWeight: correctSet.contains(i)
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "내 vs 전체" 비교 카드
// ─────────────────────────────────────────────────────────────────────────────

class _AccuracyCompareCard extends StatelessWidget {
  const _AccuracyCompareCard({
    required this.l10n,
    required this.myStat,
    required this.globalStat,
    required this.globalSupported,
    required this.loadFailed,
  });

  final AppLocalizations l10n;
  final AnswerQuestionStat? myStat;
  final GlobalQuestionStat? globalStat;
  final bool globalSupported;
  final bool loadFailed;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final myPct = myStat == null || myStat!.attempts == 0
        ? null
        : (myStat!.accuracyRate * 100).round();
    final globalPct = globalStat == null || globalStat!.attempts == 0
        ? null
        : (globalStat!.accuracyRate * 100).round();

    String diffText;
    Color diffColor;
    if (myPct == null || globalPct == null) {
      diffText = l10n.qdetailDiffNoData;
      diffColor = ac.textSecondary;
    } else {
      final diff = myPct - globalPct;
      if (diff > 3) {
        diffText = l10n.qdetailDiffHigher(diff);
        diffColor = ac.success;
      } else if (diff < -3) {
        diffText = l10n.qdetailDiffLower(-diff);
        diffColor = ac.danger;
      } else {
        diffText = l10n.qdetailDiffSame;
        diffColor = ac.textSecondary;
      }
    }

    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _BigStat(
                  label: l10n.qdetailMyAccuracy,
                  pct: myPct,
                ),
              ),
              Container(
                width: 1,
                height: 56,
                color: ac.borderLight,
              ),
              Expanded(
                child: _BigStat(
                  label: l10n.qdetailGlobalAccuracy,
                  pct: globalPct,
                  hint: !globalSupported
                      ? l10n.statsGlobalUnavailable
                      : (loadFailed ? l10n.statsGlobalLoadFailed : null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            diffText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: diffColor,
            ),
          ),
          if (globalStat != null && globalStat!.attempts > 0) ...[
            const SizedBox(height: 4),
            Text(
              l10n.qdetailAttemptsLine(globalStat!.attempts),
              style: TextStyle(
                fontSize: 11,
                color: ac.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.label, required this.pct, this.hint});

  final String label;
  final int? pct;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: ac.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          pct == null ? '—' : '$pct%',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: ac.textPrimary,
          ),
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              hint!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: ac.textSecondary),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 보기별 선택 분포
// ─────────────────────────────────────────────────────────────────────────────

class _OptionDistributionCard extends StatelessWidget {
  const _OptionDistributionCard({
    required this.l10n,
    required this.question,
    required this.globalStat,
  });

  final AppLocalizations l10n;
  final Question question;
  final GlobalQuestionStat globalStat;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final counts = globalStat.optionCounts;
    final total =
        counts.values.fold<int>(0, (sum, v) => sum + v).clamp(1, 1 << 31);
    final correctSet = question.correctIndexSet;

    // 가장 많이 선택된 오답 인덱스 — 빨강 강조용.
    int? mostWrongIdx;
    int mostWrongCount = 0;
    counts.forEach((idx, c) {
      if (!correctSet.contains(idx) && c > mostWrongCount) {
        mostWrongCount = c;
        mostWrongIdx = idx;
      }
    });

    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.qdetailOptionDistribution,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ac.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < question.options.length; i++) ...[
            _OptionBar(
              index: i,
              label: question.options[i],
              count: counts[i] ?? 0,
              total: total,
              isCorrect: correctSet.contains(i),
              isMostWrong: mostWrongIdx == i,
            ),
            if (i < question.options.length - 1)
              const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _OptionBar extends StatelessWidget {
  const _OptionBar({
    required this.index,
    required this.label,
    required this.count,
    required this.total,
    required this.isCorrect,
    required this.isMostWrong,
  });

  final int index;
  final String label;
  final int count;
  final int total;
  final bool isCorrect;
  final bool isMostWrong;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final ratio = total > 0 ? count / total : 0.0;
    final pct = (ratio * 100).round();

    final Color barColor;
    if (isCorrect) {
      barColor = ac.success;
    } else if (isMostWrong && count > 0) {
      barColor = ac.danger;
    } else {
      barColor = ac.textSecondary.withValues(alpha: 0.5);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${index + 1}. ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: ac.textSecondary,
              ),
            ),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: ac.textPrimary,
                  fontWeight: isCorrect ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: ac.chipBg,
            color: barColor,
          ),
        ),
      ],
    );
  }
}
