import 'package:flutter/material.dart';

import 'glass_background.dart';

/// 글래스 톤 Scaffold 래퍼. `Scaffold(backgroundColor: transparent,
/// extendBodyBehindAppBar: true)` + `GlassBackground(child: SafeArea(body))`.
///
/// AppBar 는 보통 `GlassAppBar` 를 함께 쓴다. 본문 ListView 가 AppBar 뒤로
/// 가려지지 않도록, 화면 측에서 ListView padding.top 에 `kToolbarHeight`
/// 정도를 가산해야 한다 (extendBodyBehindAppBar 효과).
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
