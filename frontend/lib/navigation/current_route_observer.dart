import 'package:flutter/widgets.dart';

final ValueNotifier<String> currentRouteNotifier =
    ValueNotifier<String>('/');

class CurrentRouteObserver extends NavigatorObserver {
  /// Updates must not run during [Navigator] build (e.g. restoration); that
  /// would notify [ValueListenableBuilder] inside [MaterialApp.builder] and
  /// trigger "setState/markNeedsBuild called during build" in widget tests.
  void _set(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || name.isEmpty) return;
    if (currentRouteNotifier.value == name) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentRouteNotifier.value != name) {
        currentRouteNotifier.value = name;
      }
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _set(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _set(previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _set(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

final CurrentRouteObserver currentRouteObserver = CurrentRouteObserver();

