import 'package:flutter/material.dart';
import 'package:flutter_synergy/core/widgets/global_top_banner.dart';
import 'package:flutter_synergy/core/widgets/root_scaffold_messenger_key.dart';

export 'global_top_banner.dart'
    show
        GlobalTopBanner,
        GlobalTopBannerCard,
        globalTopBannerTodayTimeLabel,
        kGlobalTopBannerBackground,
        kGlobalTopBannerErrorIconFill;
export 'root_navigator_key.dart' show rootNavigatorKey;
export 'root_scaffold_messenger_key.dart' show globalScaffoldMessengerKey;

/// App-wide toasts: bottom [SnackBar]s and top [GlobalTopBanner].
abstract final class GlobalSnackbar {
  GlobalSnackbar._();

  static ScaffoldMessengerState? get _m =>
      globalScaffoldMessengerKey.currentState;

  static void hideCurrent() => _m?.hideCurrentSnackBar();

  /// Replaces any visible snackbar and shows [snackBar].
  static void show(SnackBar snackBar) {
    final m = _m;
    if (m == null) return;
    m.hideCurrentSnackBar();
    m.showSnackBar(snackBar);
  }

  static void info(
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    show(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
  }

  static void error(
    String message, {
    Duration duration = const Duration(seconds: 5),
    SnackBarAction? action,
  }) {
    show(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFB91C1C),
        action: action,
      ),
    );
  }

  /// Top navy banner (`rgba(32, 49, 92)`). See [GlobalTopBanner] / [GlobalTopBannerCard].
  static void showTopBanner({
    required String title,
    String? subtitle,
    Widget? leading,
    Color backgroundColor = kGlobalTopBannerBackground,
    Duration visibleFor = const Duration(seconds: 5),
  }) {
    GlobalTopBanner.show(
      title: title,
      subtitle: subtitle,
      leading: leading,
      backgroundColor: backgroundColor,
      visibleFor: visibleFor,
    );
  }

  /// Top error banner: navy pill, red circle + white ✕, title + optional subtitle.
  static void showTopErrorBanner({
    required String title,
    String? subtitle,
    Duration visibleFor = const Duration(seconds: 6),
  }) {
    GlobalTopBanner.showError(
      title: title,
      subtitle: subtitle,
      visibleFor: visibleFor,
    );
  }

  static void hideTopBanner() => GlobalTopBanner.dismiss();
}
