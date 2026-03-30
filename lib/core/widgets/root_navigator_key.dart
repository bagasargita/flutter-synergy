import 'package:flutter/material.dart';

/// Passed to [GoRouter.navigatorKey] so overlays (e.g. [GlobalTopBanner]) can use
/// [NavigatorState.overlay]. [ScaffoldMessenger] sits *above* the navigator, so
/// `Overlay.maybeOf(scaffoldMessengerKey.currentContext)` is always null.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');
