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

  bool get hasSingleFace => faceCount == 1 && singleFace != null;
  bool get isGoodForCapture =>
      hasSingleFace &&
      eyesOpen &&
      singleFace!.boundingBox.width >= minFaceWidthRequiredPx;
}
