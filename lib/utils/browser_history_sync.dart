import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Web 환경에서 Flutter [Navigator] 와 브라우저 history 를 동기화하는 옵저버.
///
/// 모바일 브라우저(특히 Android Chrome)에서 시스템 뒤로가기 버튼은 곧
/// 브라우저 back 이다. Flutter Web 의 기본 동작은 익명 [MaterialPageRoute]
/// push 시 브라우저 history 에 새 엔트리를 추가하지 않으므로, 뒤로가기 한
/// 번에 앱(=탭) 자체가 닫힌다. 이 옵저버는 push/pop 시점에 직접
/// `window.history` 를 조작해 두 스택을 한 단계씩 짝맞춰 둔다.
///
/// 동기화 규칙:
/// - [didPush]: 초기 라우트가 아닌 [PageRoute] 가 push 되면 dummy state 를
///   `pushState` 로 추가하고 [_depth] 증가. 모달(`showModalBottomSheet`,
///   `showDialog`) 은 [PageRoute] 가 아니므로 자동 제외된다.
/// - `popstate` 리스너: 우리가 만든 dummy state 가 사라진 경우이므로
///   루트 [Navigator] 에 `maybePop()` 을 시도한다. 단, 내부에서 [didPop] /
///   [didRemove] 가 직접 `history.back()` 을 호출해 발생한 popstate 는
///   [_expectedConsumes] 카운터로 swallow.
/// - [didPop] / [didRemove]: 앱 내부 ← 버튼·`popUntil`·
///   `pushAndRemoveUntil` 등으로 라우트가 사라질 때, 우리가 push 했던
///   브라우저 엔트리도 같이 회수하기 위해 `history.back()` 호출.
class BrowserHistorySyncObserver extends NavigatorObserver {
  BrowserHistorySyncObserver() {
    if (kIsWeb) {
      _popStateCallback = ((web.Event _) => _onPopState()).toJS;
      web.window.addEventListener('popstate', _popStateCallback);
    }
  }

  /// 우리가 push 해서 들고 있는 브라우저 history 엔트리 수.
  int _depth = 0;

  /// 다음 popstate 를 swallow 할 횟수. 앱 내부 pop 으로 인해
  /// `history.back()` 을 직접 호출했을 때 발생하는 자기 popstate 를
  /// "진짜 브라우저 back" 으로 오해해 라우트가 한 단계 더 pop 되는 일을 막는다.
  int _expectedConsumes = 0;

  /// popstate 가 트리거한 `maybePop` 중인지 여부. 그 결과로 발생할 [didPop]
  /// 에서 `history.back()` 을 다시 호출해 무한 루프가 되지 않도록 막는다.
  bool _popFromBrowser = false;

  late final JSExportedDartFunction _popStateCallback;

  void _onPopState() {
    if (_expectedConsumes > 0) {
      _expectedConsumes--;
      return;
    }
    if (_depth <= 0) return;
    _depth--;
    _popFromBrowser = true;
    final n = navigator;
    if (n == null) {
      _popFromBrowser = false;
      return;
    }
    n.maybePop().whenComplete(() => _popFromBrowser = false);
  }

  void _consumeOne() {
    _expectedConsumes++;
    web.window.history.back();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!kIsWeb) return;
    if (route is! PageRoute) return;
    if (previousRoute == null) return;
    _depth++;
    web.window.history.pushState(null, '', web.window.location.href);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!kIsWeb) return;
    if (route is! PageRoute) return;
    if (_popFromBrowser) return;
    if (_depth <= 0) return;
    _depth--;
    _consumeOne();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!kIsWeb) return;
    if (route is! PageRoute) return;
    if (_depth <= 0) return;
    _depth--;
    _consumeOne();
  }
}
