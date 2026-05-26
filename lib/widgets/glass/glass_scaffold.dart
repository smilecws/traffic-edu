import 'package:flutter/material.dart';

import 'glass_background.dart';

/// 글래스 톤 Scaffold 래퍼. `Scaffold(backgroundColor: transparent,
/// extendBodyBehindAppBar: true)` + `GlassBackground(child: SafeArea(body))`.
///
/// AppBar 는 보통 `GlassAppBar` 를 함께 쓴다. `extendBodyBehindAppBar: true`
/// 환경에서 Scaffold 는 body 의 `MediaQuery.padding.top` 을
/// `max(statusBar, appBarHeight)` 로 세팅하고, 내부 `SafeArea` 가 이를 소비해서
/// body content 를 AppBar 바로 아래로 자동 위치시킨다. 따라서 화면 측 ListView
/// padding.top 에 `kToolbarHeight` 를 더하면 안 된다 (이중 가산이 되어 빈공간
/// 생김). 작은 시각적 버퍼(예: 12dp) 만 추가하면 충분하다.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: GlassBackground(
        child: SafeArea(child: body),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
