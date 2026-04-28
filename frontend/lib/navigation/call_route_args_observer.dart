import 'package:flutter/material.dart';

import '../services/call_route_args_storage.dart';

/// Persists `/call` route [arguments] so a Web hard-refresh on `#/call` can
/// recover the map.
class CallRouteArgsObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _maybeSave(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _maybeSave(newRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _maybeSave(Route<dynamic> route) {
    if (route.settings.name != '/call') return;
    final a = route.settings.arguments;
    if (a is! Map) return;
    callRouteArgsStorageWrite(Map<String, dynamic>.from(
      a.map((k, v) => MapEntry(k.toString(), v)),
    ));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name == '/call') {
      callRouteArgsStorageClear();
    }
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name == '/call') {
      callRouteArgsStorageClear();
    }
    super.didRemove(route, previousRoute);
  }
}
