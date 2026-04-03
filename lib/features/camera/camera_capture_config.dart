import 'dart:io';

import 'package:camera/camera.dart';

/// Camera settings that differ by platform (preview format, timing, resolution).
///
/// iOS: [enableAudio] is false and [resolutionPreset] is conservative to reduce
/// FigCapture / XPC noise (`err=-17281` logs) from an over-heavy AV capture graph.
final class CameraCaptureConfig {
  const CameraCaptureConfig({
    required this.imageFormatGroup,
    required this.analysisInterval,
    required this.resolutionPreset,
    required this.enableAudio,
    this.lockPortraitOnIos = false,
  });

  final ImageFormatGroup? imageFormatGroup;
  final Duration analysisInterval;
  final ResolutionPreset resolutionPreset;
  final bool enableAudio;

  /// Stabilizes still capture on iOS when the app is portrait-only.
  final bool lockPortraitOnIos;

  static CameraCaptureConfig forCurrentPlatform() {
    if (Platform.isIOS) {
      return const CameraCaptureConfig(
        imageFormatGroup: ImageFormatGroup.bgra8888,
        analysisInterval: Duration(milliseconds: 1200),
        resolutionPreset: ResolutionPreset.medium,
        enableAudio: false,
        lockPortraitOnIos: true,
      );
    }
    return const CameraCaptureConfig(
      imageFormatGroup: ImageFormatGroup.jpeg,
      analysisInterval: Duration(milliseconds: 600),
      resolutionPreset: ResolutionPreset.medium,
      enableAudio: false,
    );
  }
}
