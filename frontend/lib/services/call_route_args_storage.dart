// Facade: Web uses sessionStorage; VM uses in-memory.
import 'call_route_args_storage_vm.dart'
    if (dart.library.html) 'call_route_args_storage_web.dart' as storage_impl;

/// Called when [NavigatorObserver] sees push to `/call` — refresh-safe on Web.
void callRouteArgsStorageWrite(Map<String, dynamic> args) {
  storage_impl.callRouteArgsStorageWrite(args);
}

Map<String, dynamic>? callRouteArgsStorageRead() {
  return storage_impl.callRouteArgsStorageRead();
}

void callRouteArgsStorageClear() {
  storage_impl.callRouteArgsStorageClear();
}
