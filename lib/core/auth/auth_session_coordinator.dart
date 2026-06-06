import 'dart:async';

/// Bridges [AuthInterceptor] (no [WidgetRef]) to app auth + navigation.
///
/// Register a handler from [AuthSessionListener] before API calls run.
class AuthSessionCoordinator {
  AuthSessionCoordinator._();

  static final AuthSessionCoordinator instance = AuthSessionCoordinator._();

  Future<void> Function()? _onSessionExpired;
  bool _handling = false;

  void register(Future<void> Function() handler) {
    _onSessionExpired = handler;
  }

  void unregister() {
    _onSessionExpired = null;
  }

  /// Clears in-flight session expiry handling after logout + navigation.
  Future<void> notifySessionExpired() async {
    if (_handling) return;
    final handler = _onSessionExpired;
    if (handler == null) return;

    _handling = true;
    try {
      await handler();
    } finally {
      _handling = false;
    }
  }
}
