import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/access_log_config.dart';
import '../l10n/app_localizations.dart';
import '../services/access_log_service.dart';
import '../services/consent_service.dart';
import '../services/google_auth_service.dart';
import '../theme/app_theme_colors.dart';
import '../widgets/google_sign_in_button.dart';

/// 첫 실행 게이트. Google 로그인 + 이름 입력 + 동의 체크 셋 다 만족해야 통과.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key, required this.onGranted});

  final ValueChanged<ConsentRecord> onGranted;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  GoogleSignInAccount? _account;
  bool _collectionAgreed = false;
  bool _thirdPartyAgreed = false;
  bool _signingIn = false;
  bool _submitting = false;
  bool _authReady = false;
  String? _signInError;
  StreamSubscription<GoogleSignInAccount?>? _authSub;

  @override
  void initState() {
    super.initState();
    // 웹은 GIS 버튼 클릭 결과가 stream 으로만 옴. 모바일/데스크톱도 silent 결과를
    // 동일 경로로 받기 위해 둘 다 구독.
    _authSub = GoogleAuthService.onCurrentUserChanged.listen((account) {
      if (!mounted) return;
      setState(() => _account = account);
    });
    _bootstrapAuth();
  }

  // signInSilently() 호출이 google_sign_in_web 의 GoogleSignInPlugin::init() 을
  // 트리거한다. renderButton() 은 init 이 끝난 뒤에만 호출 가능하므로,
  // 완료 전까지는 GIS 버튼 빌드를 막아야 한다.
  Future<void> _bootstrapAuth() async {
    try {
      await GoogleAuthService.signInSilently();
    } catch (_) {
      // 캐시 미존재는 정상 — silent 실패해도 init 은 완료된 상태.
    }
    if (!mounted) return;
    setState(() => _authReady = true);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _signingIn = true;
      _signInError = null;
    });
    try {
      final account = await GoogleAuthService.signIn();
      if (!mounted) return;
      setState(() => _account = account);
    } catch (_) {
      if (!mounted) return;
      setState(() => _signInError = l10n.consentSignInFailed);
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  Future<void> _handleAgree() async {
    if (_account == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_collectionAgreed || !_thirdPartyAgreed) return;

    setState(() => _submitting = true);
    final name = _nameController.text.trim();
    final account = _account!;
    final record = ConsentRecord(
      sub: account.id,
      email: account.email,
      name: name,
      grantedAt: DateTime.now().toUtc(),
      version: AccessLogConfig.consentVersion,
    );

    // 로컬 저장이 우선 — 네트워크 실패해도 동의 자체는 저장.
    await ConsentService.save(record);
    // 로그 전송은 fire-and-forget. 실패 시 큐에 적재됨.
    // ignore: discarded_futures
    AccessLogService.send(eventType: 'consent_granted', name: name);

    if (!mounted) return;
    widget.onGranted(record);
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
    final canSubmit = _account != null &&
        _collectionAgreed &&
        _thirdPartyAgreed &&
        _nameController.text.trim().isNotEmpty &&
        !_submitting;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
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
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
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
                  _GoogleSignInRow(
                    account: _account,
                    busy: _signingIn,
                    authReady: _authReady,
                    error: _signInError,
                    onSignIn: _handleSignIn,
                    label: l10n.consentGoogleSignInButton,
                    signedInLabelBuilder: (e) => l10n.consentSignedInAs(e),
                    requiredLabel: l10n.consentGoogleSignInRequired,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    enabled: _account != null && !_submitting,
                    maxLength: 30,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.consentNameLabel,
                      hintText: l10n.consentNameHint,
                      filled: true,
                      fillColor: colors.surfaceWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.borderLight),
                      ),
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return l10n.consentNameRequired;
                      if (v.length > 30) return l10n.consentNameTooLong;
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _collectionAgreed,
                    onChanged: (_account == null || _submitting)
                        ? null
                        : (v) =>
                            setState(() => _collectionAgreed = v ?? false),
                    title: Text(
                      l10n.consentCollectionAgreeCheckbox,
                      style: TextStyle(color: colors.textPrimary),
                    ),
                    activeColor: colors.primary,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    value: _thirdPartyAgreed,
                    onChanged: (_account == null || _submitting)
                        ? null
                        : (v) =>
                            setState(() => _thirdPartyAgreed = v ?? false),
                    title: Text(
                      l10n.consentThirdPartyAgreeCheckbox,
                      style: TextStyle(color: colors.textPrimary),
                    ),
                    activeColor: colors.primary,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: canSubmit ? _handleAgree : null,
                    child: _submitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.onPrimary,
                            ),
                          )
                        : Text(
                            l10n.consentAgreeButton,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colors.borderLight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FlexColumnWidth(),
              },
              border: TableBorder.symmetric(
                inside: BorderSide(color: colors.borderLight, width: 0.5),
              ),
              children: [
                for (final row in rows)
                  TableRow(
                    children: [
                      Container(
                        color: colors.chipBg,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Text(
                          row.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        color: colors.surfaceWhite,
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

class _GoogleSignInRow extends StatelessWidget {
  const _GoogleSignInRow({
    required this.account,
    required this.busy,
    required this.authReady,
    required this.error,
    required this.onSignIn,
    required this.label,
    required this.signedInLabelBuilder,
    required this.requiredLabel,
  });

  final GoogleSignInAccount? account;
  final bool busy;
  final bool authReady;
  final String? error;
  final VoidCallback onSignIn;
  final String label;
  final String Function(String email) signedInLabelBuilder;
  final String requiredLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (account != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.chipBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_user_rounded, color: colors.primaryDark, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                signedInLabelBuilder(account!.email),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (kIsWeb)
          // GIS 가 직접 렌더하는 공식 버튼. signIn() programmatic 호출이
          // 막혀 있어 웹에서는 이 경로만 동작한다.
          // renderButton() 은 GoogleSignInPlugin::init() 이 끝난 뒤에만 호출
          // 가능하므로 authReady 전에는 자리만 잡아둔다.
          authReady
              ? const Align(
                  alignment: Alignment.centerLeft,
                  child: GoogleSignInWebButton(),
                )
              : const SizedBox(
                  height: 44,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
        else
          OutlinedButton.icon(
            onPressed: busy ? null : onSignIn,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textPrimary,
              backgroundColor: colors.surfaceWhite,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: colors.borderLight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                : const Icon(Icons.login),
            label:
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        const SizedBox(height: 6),
        Text(
          error ?? requiredLabel,
          style: TextStyle(
            fontSize: 12,
            color: error != null ? Colors.redAccent : colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
