import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/consent_service.dart';
import '../services/global_answer_stats_service.dart';
import '../services/global_stats_consent_service.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/glass/glass_action_button.dart';
import '../widgets/glass/glass_background.dart';
import '../widgets/glass/glass_card.dart';

/// 첫 실행 게이트. 이름 입력 + 동의 체크 2개 만족해야 통과.
///
/// 동의 시점에 [ConsentLogService] 가 Google Form 으로 이름·일자를 익명 POST 한다
/// (fire-and-forget). 로컬에는 sub/email 없이 name·grantedAt·version 만 저장.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key, required this.onGranted});

  final ValueChanged<ConsentRecord> onGranted;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _collectionAgreed = false;
  bool _globalStatsAgreed = false;
  bool _submitting = false;

  // 한글 IME 조합 중 자모(ㄱ-ㅎ, ㅏ-ㅣ)도 허용해야 입력이 막히지 않는다.
  // 숫자·이모지·특수기호는 키 입력 단계에서 차단.
  static final RegExp _allowedCharsRegExp =
      RegExp(r'[가-힣ㄱ-ㅎㅏ-ㅣa-zA-Z ]');

  // 검증 단계에서는 완성형 한글 또는 영문 알파벳이 1자 이상 있어야 통과.
  // 자모(ㅋㅋㅋ)·공백·기호만으로 구성된 이름은 거부.
  static final RegExp _letterRegExp = RegExp(r'[가-힣a-zA-Z]');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAgree() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_collectionAgreed) return;

    setState(() => _submitting = true);
    final name =
        _nameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final record = ConsentRecord(
      name: name,
      grantedAt: DateTime.now().toUtc(),
      version: ConsentService.currentVersion,
    );

    // 로컬 저장이 우선 — 네트워크 실패해도 동의 자체는 저장.
    await ConsentService.save(record);
    await GlobalStatsConsentService.save(_globalStatsAgreed);
    // 입력받은 이름을 Firebase 익명 사용자의 displayName 에 세팅 (silent).
    await _setDisplayNameSilently(name);

    if (!mounted) return;
    widget.onGranted(record);
  }

  /// 미지원 플랫폼·로그인 미완료·네트워크 실패는 모두 silent 처리.
  /// displayName 세팅 실패가 동의 게이트 진입을 막아서는 안 된다.
  Future<void> _setDisplayNameSilently(String name) async {
    if (!GlobalAnswerStatsService.isSupported) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.updateDisplayName(name);
    } catch (e) {
      debugPrint('updateDisplayName failed: $e');
    }
  }

  Future<void> _handleDecline() async {
    final l10n = AppLocalizations.of(context);
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.consentExitDialogTitle),
        content: Text(l10n.consentExitDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.consentExitCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.consentExitConfirm),
          ),
        ],
      ),
    );
    if (exit == true) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    final canSubmit = _collectionAgreed &&
        _nameController.text.trim().isNotEmpty &&
        !_submitting;

    final indigo = colors.gradientIndigo[0];
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GlassBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.consentTitle,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _PrivacyTableSection(
                      title: l10n.consentCollectionTitle,
                      rows: l10n.consentCollectionRows,
                    ),
                    const SizedBox(height: 16),
                    _PrivacyTableSection(
                      title: l10n.consentThirdPartyTitle,
                      rows: l10n.consentThirdPartyRows,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.consentRightToRefuse,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      enabled: !_submitting,
                      maxLength: 30,
                      onChanged: (_) => setState(() {}),
                      cursorColor: indigo,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(_allowedCharsRegExp),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.consentNameLabel,
                        hintText: l10n.consentNameHint,
                        labelStyle: TextStyle(color: colors.textSecondary),
                        floatingLabelStyle: TextStyle(color: indigo),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.5),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: indigo, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        final v = (value ?? '').trim();
                        if (v.isEmpty) return l10n.consentNameRequired;
                        if (v.length < 2) return l10n.consentNameTooShort;
                        if (v.length > 30) return l10n.consentNameTooLong;
                        if (!_letterRegExp.hasMatch(v)) {
                          return l10n.consentNameInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _collectionAgreed,
                      onChanged: _submitting
                          ? null
                          : (v) =>
                              setState(() => _collectionAgreed = v ?? false),
                      title: Text(
                        l10n.consentCollectionAgreeCheckbox,
                        style: TextStyle(color: colors.textPrimary),
                      ),
                      activeColor: indigo,
                      checkColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: _globalStatsAgreed,
                      onChanged: _submitting
                          ? null
                          : (v) =>
                              setState(() => _globalStatsAgreed = v ?? false),
                      title: Text(
                        l10n.consentGlobalStatsAgreeCheckbox,
                        style: TextStyle(color: colors.textPrimary),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          l10n.consentGlobalStatsDesc,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      activeColor: indigo,
                      checkColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      titleAlignment: ListTileTitleAlignment.top,
                    ),
                    const SizedBox(height: 16),
                    _submitting
                        ? SizedBox(
                            height: 52,
                            child: Center(
                              child: SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: indigo,
                                ),
                              ),
                            ),
                          )
                        : GlassActionButton(
                            label: l10n.consentAgreeButton,
                            onTap: canSubmit ? _handleAgree : null,
                            gradient: colors.gradientIndigo,
                          ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _submitting ? null : _handleDecline,
                      child: Text(
                        l10n.consentDeclineButton,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyTableSection extends StatelessWidget {
  const _PrivacyTableSection({required this.title, required this.rows});

  final String title;
  final List<({String label, String value})> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final indigo = colors.gradientIndigo[0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ),
        GlassCard(
          borderRadius: 12,
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(110),
                1: FlexColumnWidth(),
              },
              border: TableBorder.symmetric(
                inside: BorderSide(
                  color: indigo.withValues(alpha: 0.15),
                  width: 0.5,
                ),
              ),
              children: [
                for (final row in rows)
                  TableRow(
                    children: [
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.fill,
                        child: Container(
                          color: indigo.withValues(alpha: 0.12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            row.label,
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: indigo,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Text(
                          row.value,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
