import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_synergy/features/camera/face_detection_platform.dart';
import 'package:flutter_synergy/features/camera/face_detection_types.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// ML Kit face pipeline tuned for Android (camera JPEG + fast detector).
///
/// Eye open/closed uses the same lenient mapping as iOS Vision
/// ([FaceDetectionServiceIos]) so liveness (blink) behaves consistently.
final class FaceDetectionServiceAndroid implements FaceDetectionPlatform {
  FaceDetectionServiceAndroid()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(
            enableClassification: true,
            enableLandmarks: false,
            enableContours: false,
            enableTracking: false,
            minFaceSize: 0.12,
            performanceMode: FaceDetectorMode.fast,
          ),
        );

  final FaceDetector _detector;
  static const double _maxAbsYawDegrees = 18;
  static const double _maxAbsRollDegrees = 18;

  /// Mirrors iOS `_iosLenientEyePair` — tuned for blink / liveness, not rigid thresholds.
  static (bool open, bool closed) _lenientEyePair(double left, double right) {
    final hi = math.max(left, right);
    final lo = math.min(left, right);
    final avg = (left + right) * 0.5;

    var closed = avg < 0.44 || lo < 0.28 || (hi < 0.50 && avg < 0.46);
    var open = hi > 0.14 && lo > 0.10 && avg > 0.36;

    if (closed && open) {
      if (avg >= 0.40 && hi >= 0.38) {
        closed = false;
      } else {
        open = false;
      }
    }
    return (open, closed);
  }

  @override
  Future<FaceDetectionResult> processFile(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final faces = await _detector.processImage(inputImage);

    if (faces.isEmpty) {
      return const FaceDetectionResult(faceCount: 0);
    }
    if (faces.length > 1) {
      return FaceDetectionResult(faceCount: faces.length);
    }

    return _singleFaceResult(faces.first);
  }

  FaceDetectionResult _singleFaceResult(Face face) {
    final left = face.leftEyeOpenProbability;
    final right = face.rightEyeOpenProbability;
    final smile = face.smilingProbability ?? 0;
    final classificationReady = left != null && right != null;

    final bool eyesOpen;
    final bool eyesClosed;
    final yaw = face.headEulerAngleY ?? 0;
    final roll = face.headEulerAngleZ ?? 0;
    final facingForward =
        yaw.abs() <= _maxAbsYawDegrees && roll.abs() <= _maxAbsRollDegrees;
    if (classificationReady) {
      final pair = _lenientEyePair(left, right);
      eyesOpen = pair.$1;
      eyesClosed = pair.$2;
    } else {
      eyesOpen = false;
      eyesClosed = false;
    }

    return FaceDetectionResult(
      faceCount: 1,
      singleFace: face,
      faceBoundsImage: face.boundingBox,
      eyesOpen: eyesOpen,
      eyesClosed: eyesClosed,
      smiling: smile > 0.5,
      leftEyeOpenProbability: left,
      rightEyeOpenProbability: right,
      classificationAvailable: classificationReady,
      minFaceWidthRequiredPx: kAndroidMinFaceWidthForCapturePx,
      facingForward: facingForward,
    );
  }

  @override
  Future<FaceDetectionResult?> processBgra8888Preview({
    required Uint8List bytes,
    required int width,
    required int height,
    required int bytesPerRow,
  }) async =>
      null;

  @override
  Future<void> close() => _detector.close();
}
