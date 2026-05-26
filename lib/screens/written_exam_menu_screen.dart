import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/mock_exam_license_kind.dart';
import '../models/question.dart';
import '../services/attempted_questions_service.dart';
import '../services/favorite_questions_service.dart';
import '../services/question_service.dart';
import '../services/question_subcategory_service.dart';
import '../services/subcategory_classifier.dart';
import '../models/mock_exam_history_entry.dart';
import '../services/mock_exam_history_service.dart';
import '../services/user_answer_stats_service.dart';
import '../services/wrong_note_service.dart';
import '../theme/app_theme_colors.dart';
import '../utils/subcategory_ui.dart';
import '../widgets/glass/glass_background.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/glass/gradient_icon_badge.dart';
import 'mock_exam_history_screen.dart';
import 'quiz_screen.dart';
import 'stats_screen.dart';
import 'study_card_screen.dart';

/// 운전면허 학과시험 홈(스크린샷 레이아웃)
class WrittenExamMenuScreen extends StatefulWidget {
  const WrittenExamMenuScreen({super.key});

  @override
  State<WrittenExamMenuScreen> createState() => _WrittenExamMenuScreenState();
}

class _WrittenExamMenuScreenState extends State<WrittenExamMenuScreen> {
  bool _loading = true;
  Locale? _localeForCounts;

  int _totalCount = 0;
  int _attemptedCount = 0;
  int _favoriteCount = 0;
  int _wrongCount = 0;
  // ignore: unused_field — _loadCounts 에서 할당. 향후 step 에서 사용 예정.
  MockExamHistoryEntry? _latestMockExam;
  double _accuracyRate = 0;
  int _accuracyAttempts = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = Localizations.localeOf(context);
    if (_localeForCounts == null) {
      _localeForCounts = loc;
      return;
    }
    if (_localeForCounts != loc) {
      _localeForCounts = loc;
      QuestionService.setLanguageCode(loc.languageCode);
      _loadCounts();
    }
  }

  Future<void> _loadCounts() async {
    // 독립적인 I/O 호출을 병렬 실행하여 홈 화면 로딩 대기 시간을 최소화합니다.
    final fetched = await Future.wait([
      QuestionService.loadQuestionCountOnly(),
      AttemptedQuestionsService.loadAttemptedIds(),
      FavoriteQuestionsService.loadFavoriteIds(),
      WrongNoteService.loadWrongIds(),
      MockExamHistoryService.latestEntry(),
      UserAnswerStatsService.getOverallStats(),
    ]);
    if (!mounted) return;
    final overallStats = fetched[5] as OverallStats;
    setState(() {
      _totalCount = fetched[0] as int;
      _attemptedCount = (fetched[1] as Set<int>).length;
      _favoriteCount = (fetched[2] as Set<int>).length;
      _wrongCount = (fetched[3] as Set<int>).length;
      _latestMockExam = fetched[4] as MockExamHistoryEntry?;
      _accuracyRate = overallStats.accuracyRate;
      _accuracyAttempts = overallStats.totalAttempts;
      _loading = false;
    });
  }

  Future<void> _openFavorites(BuildContext context) async {
    final favIds = await FavoriteQuestionsService.loadFavoriteIds();
    if (!context.mounted) return;
    if (favIds.isEmpty) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.snackNoFavorites)),
      );
      return;
    }
    final byId = await QuestionService.loadAllQuestionsById();
    final favQs =
        favIds.map((id) => byId[id]).whereType<Question>().toList();
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: favQs,
          title: l10n.quizTitleFavorites,
          showTimerAndScore: false,
        ),
      ),
    );
    await _loadCounts();
  }

  Future<void> _openWrongNote(BuildContext context) async {
    final ids = await WrongNoteService.loadWrongIds();
    if (!context.mounted) return;
    if (ids.isEmpty) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.snackNoWrong)),
      );
      return;
    }
    final byId = await QuestionService.loadAllQuestionsById();
    final wrongQuestions =
        ids.map((id) => byId[id]).whereType<Question>().toList();
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: wrongQuestions,
          title: l10n.quizTitleWrong,
          showTimerAndScore: false,
        ),
      ),
    );
    await _loadCounts();
  }

  Future<void> _openMockExam(BuildContext context) async {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<MockExamLicenseKind>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.mockLicenseSheetTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.mockLicenseSheetHint,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: context.appColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _PracticeTypeTile(
                  title: l10n.mockLicenseLabel(MockExamLicenseKind.type1Large),
                  subtitle: l10n.mockResultPassBar(
                    MockExamLicenseKind.type1Large.passScoreMinOutOf100,
                  ),
                  icon: Icons.local_shipping_outlined,
                  color: context.appColors.chipBg,
                  onTap: () => Navigator.pop(
                    sheetContext,
                    MockExamLicenseKind.type1Large,
                  ),
                ),
                const SizedBox(height: 8),
                _PracticeTypeTile(
                  title: l10n.mockLicenseLabel(MockExamLicenseKind.type1Special),
                  subtitle: l10n.mockResultPassBar(
                    MockExamLicenseKind.type1Special.passScoreMinOutOf100,
                  ),
                  icon: Icons.precision_manufacturing_outlined,
                  color: const Color(0xFFE9F3FF),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    MockExamLicenseKind.type1Special,
                  ),
                ),
                const SizedBox(height: 8),
                _PracticeTypeTile(
                  title: l10n.mockLicenseLabel(MockExamLicenseKind.type1Normal),
                  subtitle: l10n.mockResultPassBar(
                    MockExamLicenseKind.type1Normal.passScoreMinOutOf100,
                  ),
                  icon: Icons.directions_car_outlined,
                  color: const Color(0xFFEFFBF1),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    MockExamLicenseKind.type1Normal,
                  ),
                ),
                const SizedBox(height: 8),
                _PracticeTypeTile(
                  title: l10n.mockLicenseLabel(MockExamLicenseKind.type2Normal),
                  subtitle: l10n.mockResultPassBar(
                    MockExamLicenseKind.type2Normal.passScoreMinOutOf100,
                  ),
                  icon: Icons.drive_eta_outlined,
                  color: const Color(0xFFFFF3D6),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    MockExamLicenseKind.type2Normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (choice == null || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(mockExamLicenseKind: choice),
      ),
    );
    await _loadCounts();
  }

  Future<void> _openStats(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const StatsScreen()),
    );
  }

  Future<void> _openMockExamHistory(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const MockExamHistoryScreen()),
    );
    if (context.mounted) await _loadCounts();
  }

  Future<void> _openPracticeMenu(BuildContext context) async {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<_PracticeType>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.practiceSheetTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _PracticeTypeTile(
                  title: l10n.practiceVerbalTitle,
                  subtitle: l10n.practiceVerbalSub,
                  icon: Icons.record_voice_over_outlined,
                  color: context.appColors.chipBg,
                  onTap: () =>
                      Navigator.pop(sheetContext, _PracticeType.speaking),
                ),
                const SizedBox(height: 8),
                _PracticeTypeTile(
                  title: l10n.practiceSignTitle,
                  subtitle: l10n.practiceSignSub,
                  icon: Icons.traffic_outlined,
                  color: const Color(0xFFE9F3FF),
                  onTap: () =>
                      Navigator.pop(sheetContext, _PracticeType.signAndSituation),
                ),
                const SizedBox(height: 8),
                _PracticeTypeTile(
                  title: l10n.practiceVideoTitle,
                  subtitle: l10n.practiceVideoSub,
                  icon: Icons.play_circle_outline_rounded,
                  color: const Color(0xFFFFF3D6),
                  onTap: () =>
                      Navigator.pop(sheetContext, _PracticeType.videoQuestion),
                ),
                const SizedBox(height: 8),
                _PracticeTypeTile(
                  title: l10n.practiceRandomTitle,
                  subtitle: l10n.practiceRandomSub,
                  icon: Icons.shuffle_rounded,
                  color: const Color(0xFFEFFBF1),
                  onTap: () =>
                      Navigator.pop(sheetContext, _PracticeType.randomAll),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (choice == null) return;

    List<Question> questions;
    String title;
    switch (choice) {
      case _PracticeType.speaking:
        if (!context.mounted) return;
        final subcategoryId = await _openVerbalSubcategorySheet(context);
        if (subcategoryId == null || !context.mounted) return;
        if (subcategoryId == _kAllVerbalMarker) {
          questions = await QuestionService.getRandomQuestionsByCategory(
            category: QuestionCategory.verbal,
            count: 40,
          );
          title = l10n.quizTitleVerbal;
        } else {
          questions = await QuestionService.getRandomQuestionsBySubcategory(
            subcategoryId: subcategoryId,
            count: 40,
          );
          title = l10n.quizTitleSubcategory(subcategoryId);
        }
        break;
      case _PracticeType.signAndSituation:
        questions = await QuestionService.getRandomQuestionsByCategory(
          category: QuestionCategory.signAndSituation,
          count: 40,
        );
        title = l10n.quizTitleSign;
        break;
      case _PracticeType.videoQuestion:
        questions = await QuestionService.getRandomQuestionsByCategory(
          category: QuestionCategory.video,
          count: 40,
        );
        title = l10n.quizTitleVideo;
        break;
      case _PracticeType.randomAll:
        questions = await QuestionService.getRandomQuestions(count: 40);
        title = l10n.quizTitleRandom;
        break;
    }

    if (!context.mounted || questions.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.snackNoQuestionsForType)),
        );
      }
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          questions: questions,
          title: title,
          showTimerAndScore: false,
          shuffleQuestions: true,
        ),
      ),
    );
    await _loadCounts();
  }

  /// "말문제" 선택 후 뜨는 2차 시트. 10개 소카테고리 + "전체" 옵션.
  /// 선택된 태그 ID 또는 "전체" 마커 [_kAllVerbalMarker] 를 반환. 취소 시 null.
  Future<String?> _openVerbalSubcategorySheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final counts = await QuestionSubcategoryService.loadCounts();
    if (!context.mounted) return null;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final maxSheetHeight =
            MediaQuery.sizeOf(sheetContext).height * 0.88;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.subcategorySheetTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PracticeTypeTile(
                      title: l10n.subcategoryAllVerbalTitle,
                      subtitle: l10n.subcategoryAllVerbalSub,
                      icon: Icons.shuffle_rounded,
                      color: context.appColors.chipBg,
                      onTap: () => Navigator.pop(
                        sheetContext,
                        _kAllVerbalMarker,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...SubcategoryIds.verbalSubcategoryIds.map((id) {
                      final count = counts[id] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SubcategoryTileWithStudy(
                          title: l10n.subcategoryLabel(id),
                          subtitle: l10n.subcategorySubtitle(id, count),
                          studyLabel: l10n.studyActionLabel,
                          icon: iconForSubcategory(id),
                          color: colorForSubcategory(context, id),
                          onTapPractice: () =>
                              Navigator.pop(sheetContext, id),
                          onTapStudy: () {
                            Navigator.pop(sheetContext);
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => StudyCardScreen(
                                  subcategoryId: id,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ac = context.appColors;
    final accuracyText = _accuracyAttempts > 0
        ? '${(_accuracyRate * 100).toStringAsFixed(0)}%'
        : '—';

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 헤더 ──
                Row(
                  children: [
                    if (Navigator.of(context).canPop()) ...[
                      IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.arrow_back_rounded,
                            color: ac.textPrimary),
                        tooltip: MaterialLocalizations.of(context)
                            .backButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        '${l10n.greetHello} ✨',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: ac.textSecondary,
                        ),
                      ),
                    ),
                    // 알림 + 더보기 메뉴
                    PopupMenuButton<_OverflowAction>(
                      icon: Icon(Icons.more_vert, color: ac.textPrimary),
                      tooltip: l10n.popupStatsView,
                      onSelected: (action) {
                        switch (action) {
                          case _OverflowAction.stats:
                            _openStats(context);
                            break;
                          case _OverflowAction.history:
                            _openMockExamHistory(context);
                            break;
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: _OverflowAction.stats,
                          child: Text(l10n.popupStatsView),
                        ),
                        PopupMenuItem(
                          value: _OverflowAction.history,
                          child: Text(l10n.popupMockHistory),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── 통계 2분할 ──
                _loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              // 진도
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.flag_outlined,
                                            size: 14,
                                            color: ac.gradientIndigo[0]),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.statsProgressLabel,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: ac.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: ac.textPrimary,
                                        ),
                                        children: [
                                          TextSpan(
                                              text: '$_attemptedCount'),
                                          TextSpan(
                                            text: '/$_totalCount',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: ac.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 구분선
                              Container(
                                width: 1,
                                color: ac.textSecondary.withValues(alpha: 0.2),
                              ),
                              const SizedBox(width: 14),
                              // 정답률
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.emoji_events_outlined,
                                            size: 14,
                                            color: ac.gradientAmber[0]),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.statsAccuracyLabel,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: ac.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      accuracyText,
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: ac.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                const SizedBox(height: 12),

                // ── Bento 2×2 ──
                Row(
                  children: [
                    // 모의고사 응시
                    Expanded(
                      child: _BentoCard(
                        gradient: ac.gradientCyan,
                        icon: Icons.assignment_outlined,
                        title: l10n.menuMockTitle,
                        subtitle: l10n.bentoMockSubtitle,
                        onTap: () => _openMockExam(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 오답 다시 풀기
                    Expanded(
                      child: _BentoCard(
                        gradient: ac.gradientRose,
                        icon: Icons.cancel_outlined,
                        title: l10n.menuWrongTitle,
                        subtitle: l10n.bentoWrongSubtitle,
                        badgeCount: _wrongCount,
                        onTap: () => _openWrongNote(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // 문제 풀기
                    Expanded(
                      child: _BentoCard(
                        gradient: ac.gradientIndigo,
                        icon: Icons.description_outlined,
                        title: l10n.menuPracticeTitle,
                        subtitle: l10n.bentoPracticeSubtitle,
                        onTap: () => _openPracticeMenu(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 즐겨찾기
                    Expanded(
                      child: _BentoCard(
                        gradient: ac.gradientAmber,
                        icon: Icons.star_rounded,
                        title: l10n.menuFavoritesTitle,
                        subtitle: l10n.bentoFavoritesSubtitle,
                        badgeCount: _favoriteCount,
                        onTap: () => _openFavorites(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _OverflowAction { stats, history }

enum _PracticeType { speaking, signAndSituation, videoQuestion, randomAll }

/// 소카테고리 2차 시트에서 "말문제 전체" 를 나타내는 센티넬.
/// 태그 ID 문자열과 충돌하지 않는 값이면 됨.
const String _kAllVerbalMarker = '__all_verbal__';

class _PracticeTypeTile extends StatelessWidget {
  const _PracticeTypeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.appColors.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.appColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: context.appColors.textPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.appColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 소카테고리 시트 2차 타일. 큰 영역 탭 = 바로 풀기,
/// 우측 "공부하기" 버튼 탭 = 학습 카드 화면 이동.
class _SubcategoryTileWithStudy extends StatelessWidget {
  const _SubcategoryTileWithStudy({
    required this.title,
    required this.subtitle,
    required this.studyLabel,
    required this.icon,
    required this.color,
    required this.onTapPractice,
    required this.onTapStudy,
  });

  final String title;
  final String subtitle;
  final String studyLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTapPractice;
  final VoidCallback onTapStudy;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return InkWell(
      onTap: onTapPractice,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ac.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ac.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: ac.textPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: ac.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // "공부하기" 보조 버튼 — 부모 InkWell 탭 차단을 위해 Material 로 감싼다
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTapStudy,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ac.chipBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: ac.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 14,
                        color: ac.primaryDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        studyLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ac.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bento 그리드 카드. GlassCard 안에 GradientIconBadge + 제목/부제 배치.
class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount = 0,
  });

  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GradientIconBadge(gradient: gradient, icon: icon),
                  const Spacer(),
                  if (badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: gradient[1],
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: ac.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: ac.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
