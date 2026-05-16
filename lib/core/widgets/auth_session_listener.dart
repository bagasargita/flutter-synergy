import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/core/auth/auth_session_coordinator.dart';
import 'package:flutter_synergy/core/router/app_router.dart';
import 'package:flutter_synergy/core/widgets/global_snackbar.dart';
import 'package:flutter_synergy/features/auth/auth_controller.dart';
import 'package:flutter_synergy/features/auth/auth_provider.dart';

/// Registers session-expiry handling so [AuthInterceptor] can log the user out.
class AuthSessionListener extends ConsumerStatefulWidget {
  const AuthSessionListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AuthSessionListener> createState() =>
      _AuthSessionListenerState();
}

class _AuthSessionListenerState extends ConsumerState<AuthSessionListener> {
  @override
  void initState() {
    super.initState();
    AuthSessionCoordinator.instance.register(_onSessionExpired);
  }

  @override
  void dispose() {
    AuthSessionCoordinator.instance.unregister();
    super.dispose();
  }

  Future<void> _onSessionExpired() async {
    final status = ref.read(authControllerProvider).status;
    if (status == AuthStatus.unauthenticated) return;

    GlobalSnackbar.hideTopBanner();
    GlobalSnackbar.hideCurrent();

    await ref.read(authControllerProvider.notifier).logout();
    ref.read(routerProvider).go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
