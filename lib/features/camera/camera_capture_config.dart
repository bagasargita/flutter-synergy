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
    this.autoCaptureAfterVerification = true,
    this.postStillCaptureCooldown = Duration.zero,
  });

  final ImageFormatGroup? imageFormatGroup;
  final Duration analysisInterval;
  final ResolutionPreset resolutionPreset;
  final bool enableAudio;

  /// Stabilizes still capture on iOS when the app is portrait-only.
  final bool lockPortraitOnIos;

  /// After liveness passes, take the final photo automatically (uses silent BGRA
  /// snapshot on iOS when available, else still capture).
  final bool autoCaptureAfterVerification;

  /// Brief pause after each analysis still on iOS so AVFoundation can settle.
  final Duration postStillCaptureCooldown;

  static CameraCaptureConfig forCurrentPlatform() {
    if (Platform.isIOS) {
      return const CameraCaptureConfig(
        // BGRA matches preview stream for silent Vision analysis (no [takePicture]).
        imageFormatGroup: ImageFormatGroup.bgra8888,
        analysisInterval: Duration(milliseconds: 2000),
        resolutionPreset: ResolutionPreset.medium,
        enableAudio: false,
        lockPortraitOnIos: true,
        autoCaptureAfterVerification: true,
        // Preview path avoids still capture during scan; keep small cooldown if we fall back.
        postStillCaptureCooldown: Duration(milliseconds: 120),
      );
    }
    // Android: no automatic shutter after liveness — user must tap Capture.
    return const CameraCaptureConfig(
      imageFormatGroup: ImageFormatGroup.jpeg,
      analysisInterval: Duration(milliseconds: 600),
      resolutionPreset: ResolutionPreset.medium,
      enableAudio: false,
      autoCaptureAfterVerification: true,
    );
  }
}
