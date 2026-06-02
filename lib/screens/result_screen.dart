import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/mock_exam_license_kind.dart';
import '../models/session_result.dart';
import '../services/global_answer_stats_service.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/glass/glass_action_button.dart';
import '../widgets/glass/glass_app_bar.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/glass/glass_scaffold.dart';
import 'question_detail_screen.dart';
import 'quiz_screen.dart';
import 'written_exam_menu_screen.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final List<SessionResult> results;
  final MockExamLicenseKind? mockExamLicenseKind;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.results,
    this.mockExamLicenseKind,
  });

  int get _scaledScoreOutOf100 =>
      total <= 0 ? 0 : ((score * 100) / total).round();

  String _gradeLabel(AppLocalizations l10n) {
    if (mockExamLicenseKind != null) {
      final passed = _scaledScoreOutOf100 >=
          mockExamLicenseKind!.passScoreMinOutOf100;
      return passed ? l10n.mockResultPass : l10n.mockResultFail;
    }
    final ratio = total <= 0 ? 0.0 : score / total;
    if (ratio >= 0.9) return '🏆 우수';
    if (ratio >= 0.7) return '👍 양호';
    if (ratio >= 0.5) return '📚 보통';
    return '💪 분발';
  }

  Color _scoreColor(AppThemeColors ac) {
    if (mockExamLicenseKind != null) {
      final passed = _scaledScoreOutOf100 >=
          mockExamLicenseKind!.passScoreMinOutOf100;
      return passed ? ac.success : ac.danger;
    }
    final ratio = total <= 0 ? 0.0 : score / total;
    if (ratio >= 0.9) return ac.success;
    if (ratio >= 0.7) return ac.primaryDark;
    if (ratio >= 0.5) return ac.warning;
    return ac.danger;
  }

  String _indicesToLabels(SessionResult r, Iterable<int> indices) {
    return indices
        .map((i) => '${i + 1}. ${r.question.options[i]}')
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final l10n = AppLocalizations.of(context);
    final gradeLabel = _gradeLabel(l10n);
    final scoreColor = _scoreColor(ac);
    final kind = mockExamLicenseKind;
    final incorrectResults =
        results.where((r) => !r.isCorrect).toList();

    return GlassScaffold(
      appBar: const GlassAppBar(
        title: Text('시험 결과'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: GlassCard(
              borderRadius: 16,
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              child: kind == null
                ? Column(
                    children: [
                      Text(
                        gradeLabel,
                        style: TextStyle(
                          fontSize: 20,
                          color: ac.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$score / $total',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        total <= 0
                            ? '—'
                            : '정답률 ${(score / total * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13,
                          color: ac.textSecondary,
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              gradeLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: ac.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$score / $total',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              total <= 0
                                  ? '—'
                                  : '정답률 ${(score / total * 100).toStringAsFixed(1)}%',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: ac.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              l10n.mockResultScaledScore(_scaledScoreOutOf100),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: ac.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.mockResultLicenseKindLine}: ${l10n.mockLicenseLabel(kind)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.25,
                                color: ac.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.mockResultPassBar(kind.passScoreMinOutOf100),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.25,
                                color: ac.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '오답 노트',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ac.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: incorrectResults.length,
              itemBuilder: (context, index) {
                final r = incorrectResults[index];
                return _IncorrectCard(
                  result: r,
                  questionNumber: results.indexOf(r) + 1,
                  indicesToLabels: _indicesToLabels,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        // 결과 → 필기시험 메뉴. 스택은 [HomeScreen,
                        // WrittenExamMenuScreen] 로 정리해 이후 ← 한 번에 홈으로
                        // 빠질 수 있게 한다. 퀴즈 화면 홈 아이콘 동작과 동일.
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WrittenExamMenuScreen(),
                          ),
                          (r) => r.isFirst,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ac.gradientIndigo[0],
                        side: BorderSide(
                          color: ac.gradientIndigo[0]
                              .withValues(alpha: 0.45),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '홈으로',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassActionButton(
                    label: '다시 풀기',
                    gradient: ac.gradientIndigo,
                    onTap: () {
                      // 같은 문항 세트로 새 세션을 시작한다. mockExamLicenseKind 가
                      // 있으면 모의고사(40분 타이머), 없으면 연습 모드. 결과 화면을
                      // pushReplacement 로 갈아끼워 result→quiz→result 스택이 쌓이지
                      // 않도록 한다.
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            questions: results
                                .map((r) => r.question)
                                .toList(growable: false),
                            showTimerAndScore: mockExamLicenseKind != null,
                            mockExamLicenseKind: mockExamLicenseKind,
                          ),
                        ),
                      );
                    },
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
// 오답 카드 — 글로벌 정답률 배지 + 탭 시 QuestionDetailScreen 진입
// ─────────────────────────────────────────────────────────────────────────────

class _IncorrectCard extends StatefulWidget {
  const _IncorrectCard({
    required this.result,
    required this.questionNumber,
    required this.indicesToLabels,
  });

  final SessionResult result;
  final int questionNumber;
  final String Function(SessionResult, Iterable<int>) indicesToLabels;

  @override
  State<_IncorrectCard> createState() => _IncorrectCardState();
}

class _IncorrectCardState extends State<_IncorrectCard> {
  GlobalQuestionStat? _global;

  @override
  void initState() {
    super.initState();
    _loadGlobal();
  }

  Future<void> _loadGlobal() async {
    if (!GlobalAnswerStatsService.isSupported) return;
    final stat =
        await GlobalAnswerStatsService.loadStat(widget.result.questionId);
    if (!mounted) return;
    setState(() => _global = stat);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final l10n = AppLocalizations.of(context);
    final r = widget.result;
    final question = r.question;
    final selected = r.selectedIndices;
    final globalPct = (_global == null || _global!.attempts == 0)
        ? null
        : (_global!.accuracyRate * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderRadius: 12,
        padding: EdgeInsets.zero,
        borderColor: ac.dangerBorder,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuestionDetailScreen(question: question),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Q${widget.questionNumber}. ${question.question}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: ac.textPrimary,
                        ),
                      ),
                    ),
                    if (globalPct != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ac.chipBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: ac.borderLight),
                        ),
                        child: Text(
                          l10n.statsGlobalAccuracyBadge('$globalPct'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: ac.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                if (question.isMultipleChoice) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.close, color: ac.danger, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '내 답: ${selected.isNotEmpty ? widget.indicesToLabels(r, selected) : "(선택 없음)"}',
                          style: TextStyle(color: ac.danger),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check, color: ac.success, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '정답: ${widget.indicesToLabels(r, question.correctIndices)}',
                          style: TextStyle(color: ac.success),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  if (selected.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.close, color: ac.danger, size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '내 답: ${question.options[selected.first]}',
                            style: TextStyle(color: ac.danger),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check, color: ac.success, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '정답: ${question.options[question.correctIndices.first]}',
                          style: TextStyle(color: ac.success),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  question.explanation,
                  style: TextStyle(
                    fontSize: 13,
                    color: ac.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
