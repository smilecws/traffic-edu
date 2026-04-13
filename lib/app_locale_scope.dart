import 'package:flutter/material.dart';

/// 앱 루트에서 로케일 변경 콜백을 하위 화면에 전달합니다.
class AppLocaleScope extends InheritedWidget {
  const AppLocaleScope({
    super.key,
    required this.setLocale,
    required super.child,
  });

  final void Function(Locale locale) setLocale;

  static AppLocaleScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AppLocaleScope oldWidget) => false;
}
