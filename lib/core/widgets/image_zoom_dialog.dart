import 'package:flutter/material.dart';

/// Full-screen image viewer with pinch / pan zoom ([InteractiveViewer]).
///
/// Provide exactly one of [networkUrl] or [assetPath].
Future<void> showImageZoomDialog({
  required BuildContext context,
  String? networkUrl,
  String? assetPath,
}) async {
  final url = networkUrl?.trim() ?? '';
  final asset = assetPath?.trim() ?? '';
  if (url.isEmpty && asset.isEmpty) return;

  await showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (ctx) => _ImageZoomDialogBody(
      networkUrl: url.isNotEmpty ? url : null,
      assetPath: asset.isNotEmpty ? asset : null,
    ),
  );
}

class _ImageZoomDialogBody extends StatelessWidget {
  const _ImageZoomDialogBody({this.networkUrl, this.assetPath});

  final String? networkUrl;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final useNetwork = networkUrl != null && networkUrl!.isNotEmpty;
    final useAsset = assetPath != null && assetPath!.isNotEmpty;
    if (!useNetwork && !useAsset) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.sizeOf(context);
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              clipBehavior: Clip.none,
              minScale: 0.5,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: Center(
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: useNetwork
                      ? Image.network(
                          networkUrl!,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: cs.primary,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, _, _) =>
                              const _ZoomError(message: 'Could not load image'),
                        )
                      : Image.asset(
                          assetPath!,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorBuilder: (_, _, _) =>
                              const _ZoomError(message: 'Could not load image'),
                        ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Material(
                  color: Colors.black38,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    iconSize: 28,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomError extends StatelessWidget {
  const _ZoomError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    const fg = Colors.white70;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined, size: 56, color: fg),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: fg, fontSize: 15)),
        ],
      ),
    );
  }
}
