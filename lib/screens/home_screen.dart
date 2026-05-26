import 'package:flutter/material.dart';

import '../app_settings_scope.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/glass/glass_background.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/glass/gradient_icon_badge.dart';
import 'exam_guide_screen.dart';
import 'study_screen.dart';
import 'written_exam_menu_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _confirmRevokeConsent(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final scope = AppSettingsScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.revokeConsentDialogTitle),
        content: Text(l10n.revokeConsentDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.revokeConsentCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.revokeConsentConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await scope.revokeConsent();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. 헤더 ──
                _buildHeader(context, colors, l10n),
                const SizedBox(height: 16),

                // ── 2. 빠른 진입 통계바 (3분할) ──
                _buildStatsBar(colors, l10n),
                const SizedBox(height: 12),

                // ── 3. 메인 2분할 ──
                _buildMainCards(context, colors, l10n),
                const SizedBox(height: 12),

                // ── 4. 가로 3분할 ──
                _buildTripleCards(context, colors, l10n),
                const SizedBox(height: 12),

                // ── 5. 외부 페이지 섹션 ──
                _buildExternalSection(context, colors, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 헤더: 좌측 라벨+제목, 우측 PopupMenu ──
  Widget _buildHeader(
    BuildContext context,
    AppThemeColors colors,
    AppLocalizations l10n,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeHeaderLabel.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 2.0,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.homeHeaderTitle,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        GlassCard(
          borderRadius: 18,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: 36,
            height: 36,
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: colors.textSecondary),
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'revoke') _confirmRevokeConsent(context);
              },
              itemBuilder: (ctx) => [
                PopupMenuItem<String>(
                  value: 'revoke',
                  child: Text(l10n.menuRevokeConsent),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 통계바 3분할 ──
  Widget _buildStatsBar(AppThemeColors colors, AppLocalizations l10n) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.menu_book_outlined,
              iconColor: colors.primaryDark,
              label: l10n.homeStatsLecture,
              value: '—',
              sub: l10n.homeComingSoon,
              colors: colors,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: colors.textSecondary.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.check_box_outlined,
              iconColor: const Color(0xFF0891B2),
              label: l10n.homeStatsPrep,
              value: '—',
              sub: l10n.homeComingSoon,
              colors: colors,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: colors.textSecondary.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.event_available_outlined,
              iconColor: const Color(0xFFE11D48),
              label: l10n.homeStatsReservation,
              value: '—',
              sub: l10n.homeComingSoon,
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }

  // ── 메인 2분할: 학습하기 + 문제 풀기 ──
  Widget _buildMainCards(
    BuildContext context,
    AppThemeColors colors,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        Expanded(
          child: _BentoMainCard(
            gradient: colors.gradientEmerald,
            icon: Icons.menu_book_outlined,
            title: l10n.homeStudyTitle,
            subtitle: l10n.homeStudySub,
            colors: colors,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StudyScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BentoMainCard(
            gradient: colors.gradientIndigo,
            icon: Icons.description_outlined,
            title: l10n.homePracticeTitle,
            subtitle: l10n.homePracticeSub,
            colors: colors,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WrittenExamMenuScreen()),
            ),
          ),
        ),
      ],
    );
  }

  // ── 가로 3분할 ──
  Widget _buildTripleCards(
    BuildContext context,
    AppThemeColors colors,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        // 면허시험 순서
        Expanded(
          child: _BentoSmallCard(
            gradient: colors.gradientViolet,
            icon: Icons.format_list_numbered,
            label: l10n.navExamOrder.replaceAll(' ', '\n'),
            badgeText: l10n.homeExamStepsBadge,
            badgeColor: const Color(0xFF6D28D9),
            badgeBgColor: const Color(0xFFEDE9FE).withValues(alpha: 0.6),
            colors: colors,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExamGuideScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // 준비물 가이드
        Expanded(
          child: _BentoSmallCard(
            gradient: colors.gradientTeal,
            icon: Icons.check_box_outlined,
            label: l10n.navPrep.replaceAll(' ', '\n'),
            colors: colors,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PreparationGuideScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // 자주묻는 질문
        Expanded(
          child: _BentoSmallCard(
            gradient: colors.gradientAmber,
            icon: Icons.star_rounded,
            label: l10n.homeFaqTitle,
            badgeText: 'NEW',
            badgeColor: const Color(0xFFB45309),
            badgeBgColor: const Color(0xFFFEF3C7).withValues(alpha: 0.6),
            colors: colors,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.snackComingSoon)),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── 외부 페이지 섹션 ──
  Widget _buildExternalSection(
    BuildContext context,
    AppThemeColors colors,
    AppLocalizations l10n,
  ) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Icon(
                  Icons.open_in_new,
                  size: 12,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.homeExternalSection.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 특별교육 일정
          _ExternalLinkTile(
            gradient: colors.gradientRose,
            icon: Icons.school_outlined,
            title: l10n.navEduSchedule,
            subtitle: l10n.homeEduScheduleDesc,
            colors: colors,
            onTap: () => ExamGuideScreen.openEducationSchedulePage(context),
          ),
          // divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          // 면허시험 일정
          _ExternalLinkTile(
            gradient: colors.gradientIndigo,
            icon: Icons.event_available_outlined,
            title: l10n.navTestSchedule,
            subtitle: l10n.homeTestScheduleDesc,
            colors: colors,
            onTap: () => ExamGuideScreen.openSchedulePage(context),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── Private widgets ───────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
    required this.colors,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                  letterSpacing: 1.2,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 8,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoMainCard extends StatelessWidget {
  const _BentoMainCard({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final AppThemeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientIconBadge(gradient: gradient, icon: icon),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoSmallCard extends StatelessWidget {
  const _BentoSmallCard({
    required this.gradient,
    required this.icon,
    required this.label,
    this.badgeText,
    this.badgeColor,
    this.badgeBgColor,
    required this.colors,
    required this.onTap,
  });

  final List<Color> gradient;
  final IconData icon;
  final String label;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeBgColor;
  final AppThemeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              GradientIconBadge(gradient: gradient, icon: icon),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  height: 1.3,
                  color: colors.textPrimary,
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExternalLinkTile extends StatelessWidget {
  const _ExternalLinkTile({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final AppThemeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            GradientIconBadge(
              gradient: gradient,
              icon: icon,
              size: 32,
              iconSize: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      fontSize: 9,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.north_east,
              size: 16,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
