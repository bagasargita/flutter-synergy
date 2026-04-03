import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_synergy/core/widgets/root_navigator_key.dart';

/// Default top-banner background: `rgba(32, 49, 92, 1)`.
const Color kGlobalTopBannerBackground = Color.fromRGBO(32, 49, 92, 1);

/// Solid red for [errorLeading] (white ✕ on top).
const Color kGlobalTopBannerErrorIconFill = Color(0xFFDC2626);

/// e.g. `Today 8:23 AM` for banner subtitles.
String globalTopBannerTodayTimeLabel(DateTime at) {
  final t = at.toLocal();
  var h = t.hour;
  final m = t.minute;
  final period = h >= 12 ? 'PM' : 'AM';
  h = h % 12;
  if (h == 0) h = 12;
  final mm = m.toString().padLeft(2, '0');
  return 'Today $h:$mm $period';
}

/// Navy card at the **top** of the screen (overlay). Use [GlobalTopBanner.show] / [dismiss].
class GlobalTopBannerCard extends StatelessWidget {
  const GlobalTopBannerCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.backgroundColor = kGlobalTopBannerBackground,
    this.onDismiss,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 4, 12),
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Color backgroundColor;
  final VoidCallback? onDismiss;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  /// Green circle + check (common success pattern).
  static Widget successLeading() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF22C55E), width: 2),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.check_rounded,
        color: Color(0xFF22C55E),
        size: 26,
      ),
    );
  }

  /// Solid red circle + white ✕ (error pattern).
  static Widget errorLeading() {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: kGlobalTopBannerErrorIconFill,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withValues(alpha: 0.65),
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Inserts [GlobalTopBannerCard] into the root [Overlay] (no [BuildContext] from routes).
abstract final class GlobalTopBanner {
  GlobalTopBanner._();

  static OverlayEntry? _entry;
  static Timer? _autoDismissTimer;

  static void dismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _entry?.remove();
    _entry = null;
  }

  /// Shows a top banner; replaces any existing one.
  static void show({
    required String title,
    String? subtitle,
    Widget? leading,
    Color backgroundColor = kGlobalTopBannerBackground,
    Duration visibleFor = const Duration(seconds: 5),
    double topPadding = 10,
    double horizontalMargin = 16,
    double borderRadius = 20,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.fromLTRB(
      14,
      12,
      4,
      12,
    ),
  }) {
    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        show(
          title: title,
          subtitle: subtitle,
          leading: leading,
          backgroundColor: backgroundColor,
          visibleFor: visibleFor,
          topPadding: topPadding,
          horizontalMargin: horizontalMargin,
          borderRadius: borderRadius,
          contentPadding: contentPadding,
        );
      });
      return;
    }

    dismiss();

    _entry = OverlayEntry(
      builder: (context) {
        final topInset = MediaQuery.of(context).padding.top + topPadding;
        return Positioned(
          top: topInset,
          left: horizontalMargin,
          right: horizontalMargin,
          child: Material(
            color: Colors.transparent,
            child: GlobalTopBannerCard(
              title: title,
              subtitle: subtitle,
              leading: leading,
              backgroundColor: backgroundColor,
              onDismiss: dismiss,
              borderRadius: borderRadius,
              padding: contentPadding,
            ),
          ),
        );
      },
    );

    overlay.insert(_entry!);
    _autoDismissTimer = Timer(visibleFor, dismiss);
  }

  /// Error style: pill radius (~30), red icon, same navy background.
  static void showError({
    required String title,
    String? subtitle,
    Duration visibleFor = const Duration(seconds: 6),
    double topPadding = 10,
    double horizontalMargin = 16,
  }) {
    show(
      title: title,
      subtitle: subtitle,
      leading: GlobalTopBannerCard.errorLeading(),
      visibleFor: visibleFor,
      topPadding: topPadding,
      horizontalMargin: horizontalMargin,
      borderRadius: 30,
      contentPadding: const EdgeInsets.fromLTRB(18, 14, 6, 14),
    );
  }
}
