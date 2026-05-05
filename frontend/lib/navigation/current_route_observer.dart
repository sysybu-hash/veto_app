import 'package:flutter/widgets.dart';

final ValueNotifier<String> currentRouteNotifier =
    ValueNotifier<String>('/');

class CurrentRouteObserver extends NavigatorObserver {
  void _set(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null && name.isNotEmpty) {
      currentRouteNotifier.value = name;
    }
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

