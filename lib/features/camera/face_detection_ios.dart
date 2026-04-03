import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_synergy/features/camera/face_detection_platform.dart';
import 'package:flutter_synergy/features/camera/face_detection_types.dart';

/// iOS face pipeline using **Apple Vision** ([VNDetectFaceLandmarksRequest]) via a
/// native method channel — no Google ML Kit on the Dart side (avoids ML Kit iOS
/// telemetry / binding issues). Eye state is a **landmark heuristic**, not ML Kit
/// classification.
final class FaceDetectionServiceIos implements FaceDetectionPlatform {
  static const MethodChannel _channel = MethodChannel(
    'com.synergy.flutter_synergy/vision_face',
  );

  /// Aligned with landmark-based [eyeOpennessHeuristic] in Swift (span / 0.18).
  static const double _openThreshold = 0.34;
  static const double _closedThreshold = 0.38;

  @override
  Future<FaceDetectionResult> processFile(String path) async {
    await _waitForCaptureFile(path);

    Map<String, dynamic> map;
    try {
      final raw = await _channel.invokeMethod<dynamic>('analyzeStillImage', {
        'path': path,
      });
      if (raw is! Map) {
        return const FaceDetectionResult(
          faceCount: 0,
          minFaceWidthRequiredPx: kIosMinFaceWidthForCapturePx,
        );
      }
      map = Map<String, dynamic>.from(raw);
    } on MissingPluginException {
      return const FaceDetectionResult(
        faceCount: 0,
        minFaceWidthRequiredPx: kIosMinFaceWidthForCapturePx,
      );
    } on PlatformException {
      return const FaceDetectionResult(
        faceCount: 0,
        minFaceWidthRequiredPx: kIosMinFaceWidthForCapturePx,
      );
    }

    final count = (map['faceCount'] as num?)?.toInt() ?? 0;
    if (count == 0) {
      return const FaceDetectionResult(
        faceCount: 0,
        minFaceWidthRequiredPx: kIosMinFaceWidthForCapturePx,
      );
    }
    if (count > 1) {
      return FaceDetectionResult(
        faceCount: count,
        minFaceWidthRequiredPx: kIosMinFaceWidthForCapturePx,
      );
    }

    final boundsRaw = map['bounds'];
    Rect? faceBounds;
    if (boundsRaw is List && boundsRaw.length == 4) {
      faceBounds = Rect.fromLTWH(
        (boundsRaw[0] as num).toDouble(),
        (boundsRaw[1] as num).toDouble(),
        (boundsRaw[2] as num).toDouble(),
        (boundsRaw[3] as num).toDouble(),
      );
    }

    final classReady = map['classificationAvailable'] == true;
    final left = (map['leftEyeOpen'] as num?)?.toDouble();
    final right = (map['rightEyeOpen'] as num?)?.toDouble();

    final bool eyesOpen;
    final bool eyesClosed;
    if (classReady && left != null && right != null) {
      eyesOpen = left > _openThreshold && right > _openThreshold;
      eyesClosed = left < _closedThreshold && right < _closedThreshold;
    } else {
      eyesOpen = false;
      eyesClosed = false;
    }

    return FaceDetectionResult(
      faceCount: 1,
      faceBoundsImage: faceBounds,
      eyesOpen: eyesOpen,
      eyesClosed: eyesClosed,
      smiling: false,
      leftEyeOpenProbability: left,
      rightEyeOpenProbability: right,
      classificationAvailable: classReady,
      minFaceWidthRequiredPx: kIosMinFaceWidthForCapturePx,
    );
  }

  Future<void> _waitForCaptureFile(String path) async {
    final file = File(path);
    for (var i = 0; i < 16; i++) {
      if (file.existsSync()) {
        final len = file.lengthSync();
        if (len > 512) return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  @override
  Future<void> close() async {}
}
