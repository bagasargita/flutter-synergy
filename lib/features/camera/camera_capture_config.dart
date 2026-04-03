import 'dart:io';

import 'package:camera/camera.dart';

/// Camera settings that differ by platform (preview format, timing, resolution).
final class CameraCaptureConfig {
  const CameraCaptureConfig({
    required this.imageFormatGroup,
    required this.analysisInterval,
    required this.resolutionPreset,
  });

  final ImageFormatGroup imageFormatGroup;
  final Duration analysisInterval;
  final ResolutionPreset resolutionPreset;

  static CameraCaptureConfig forCurrentPlatform() {
    if (Platform.isIOS) {
      return const CameraCaptureConfig(
        imageFormatGroup: ImageFormatGroup.bgra8888,
        analysisInterval: Duration(milliseconds: 1000),
        resolutionPreset: ResolutionPreset.high,
      );
    }
    return const CameraCaptureConfig(
      imageFormatGroup: ImageFormatGroup.jpeg,
      analysisInterval: Duration(milliseconds: 600),
      resolutionPreset: ResolutionPreset.medium,
    );
  }
}
