import 'dart:io';

import 'package:flutter_synergy/features/camera/face_detection_platform.dart';
import 'package:flutter_synergy/features/camera/face_detection_types.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// ML Kit face pipeline tuned for iOS (still JPEG from [takePicture], BGRA preview).
///
/// iOS differences: accurate detector, file settle before read, empty-result retry,
/// slightly looser eye thresholds and smaller min face width in pixels.
final class FaceDetectionServiceIos implements FaceDetectionPlatform {
  FaceDetectionServiceIos()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(
            enableClassification: true,
            enableLandmarks: false,
            enableContours: false,
            enableTracking: false,
            minFaceSize: 0.08,
            performanceMode: FaceDetectorMode.accurate,
          ),
        );

  final FaceDetector _detector;

  /// Slightly looser than Android — iOS probabilities often sit in a narrower band.
  static const double _openThreshold = 0.34;
  static const double _closedThreshold = 0.38;

  @override
  Future<FaceDetectionResult> processFile(String path) async {
    await _waitForCaptureFile(path);

    var faces = await _detect(path);
    if (faces.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      faces = await _detect(path);
    }

    if (faces.isEmpty) {
      return const FaceDetectionResult(
        faceCount: 0,
        minFaceWidthRequiredPx: kIosMinFaceWidthForCapturePx,
      );
    }
    if (faces.length > 1) {
      return FaceDetectionResult(
        faceCount: faces.length,
        minFaceWidthRequiredPx: kIosMinFaceWidthForCapturePx,
      );
    }

    return _singleFaceResult(faces.first);
  }

  Future<List<Face>> _detect(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    return _detector.processImage(inputImage);
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

  FaceDetectionResult _singleFaceResult(Face face) {
    final left = face.leftEyeOpenProbability;
    final right = face.rightEyeOpenProbability;
    final smile = face.smilingProbability ?? 0;
    final classificationReady = left != null && right != null;

    final bool eyesOpen;
    final bool eyesClosed;
    if (classificationReady) {
      eyesOpen = left > _openThreshold && right > _openThreshold;
      eyesClosed = left < _closedThreshold && right < _closedThreshold;
    } else {
      eyesOpen = false;
      eyesClosed = false;
    }

    return FaceDetectionResult(
      faceCount: 1,
      singleFace: face,
      eyesOpen: eyesOpen,
      eyesClosed: eyesClosed,
      smiling: smile > 0.5,
      leftEyeOpenProbability: left,
      rightEyeOpenProbability: right,
      classificationAvailable: classificationReady,
      minFaceWidthRequiredPx: kIosMinFaceWidthForCapturePx,
    );
  }

  @override
  Future<void> close() => _detector.close();
}
