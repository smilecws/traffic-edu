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

                // ── 2. 메인 2분할 ──
                _buildMainCards(context, colors, l10n),
                const SizedBox(height: 12),

                // ── 3. 보조 2분할 (메인 톤과 동일) ──
                _buildSecondaryCards(context, colors, l10n),
                const SizedBox(height: 12),

                // ── 4. 외부 페이지 섹션 ──
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
              icon:
                  Icon(Icons.more_vert, size: 18, color: colors.textSecondary),
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

  // ── 보조 2분할 (메인 카드 톤과 동일) ──
  Widget _buildSecondaryCards(
    BuildContext context,
    AppThemeColors colors,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        // 면허시험 순서
        Expanded(
          child: _BentoMainCard(
            gradient: colors.gradientViolet,
            icon: Icons.format_list_numbered,
            title: l10n.navExamOrder,
            subtitle: l10n.homeMenuExamOrderSub,
            colors: colors,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExamGuideScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // 준비물 가이드
        Expanded(
          child: _BentoMainCard(
            gradient: colors.gradientTeal,
            icon: Icons.check_box_outlined,
            title: l10n.navPrep,
            subtitle: l10n.homeMenuPrepSub,
            colors: colors,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PreparationGuideScreen(),
              ),
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              GradientIconBadge(gradient: gradient, icon: icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            GradientIconBadge(gradient: gradient, icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
            Icon(
              Icons.north_east,
              size: 18,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
