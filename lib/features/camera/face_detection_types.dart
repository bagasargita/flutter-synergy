import 'dart:ui' show Rect;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Android: medium preset faces are usually wide enough; keep a modest pixel floor.
const double kAndroidMinFaceWidthForCapturePx = 48;

/// iOS: front + medium/high can yield narrower boxes in pixels; slightly lower bar.
const double kIosMinFaceWidthForCapturePx = 36;

/// Result of running face detection + classification on an image.
class FaceDetectionResult {
  const FaceDetectionResult({
    required this.faceCount,
    this.singleFace,
    this.faceBoundsImage,
    this.eyesOpen = false,
    this.eyesClosed = false,
    this.smiling = false,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.classificationAvailable = true,
    this.minFaceWidthRequiredPx = kAndroidMinFaceWidthForCapturePx,
  });

  final int faceCount;
  final Face? singleFace;

  /// Image-space face rect in pixels (top-left origin). Set on iOS (Vision) paths
  /// where [singleFace] is null; Android may set both for consistency.
  final Rect? faceBoundsImage;

  final bool eyesOpen;

  /// True when both eyes are closed (for blink detection).
  final bool eyesClosed;
  final bool smiling;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;

  /// False when the native detector did not report eye probabilities (rare).
  final bool classificationAvailable;

  /// Platform-specific minimum face width (image pixels) for [isGoodForCapture].
  final double minFaceWidthRequiredPx;

  Rect? get effectiveFaceBounds => faceBoundsImage ?? singleFace?.boundingBox;

  bool get hasSingleFace => faceCount == 1 && effectiveFaceBounds != null;

  bool get isGoodForCapture {
    final box = effectiveFaceBounds;
    return faceCount == 1 &&
        box != null &&
        eyesOpen &&
        box.width >= minFaceWidthRequiredPx;
  }
}
