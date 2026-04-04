import 'dart:typed_data';

import 'package:flutter_synergy/features/camera/face_detection_platform.dart';
import 'package:flutter_synergy/features/camera/face_detection_types.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// ML Kit face pipeline tuned for Android (camera JPEG + fast detector).
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

  static const double _openThreshold = 0.4;
  static const double _closedThreshold = 0.35;

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
      faceBoundsImage: face.boundingBox,
      eyesOpen: eyesOpen,
      eyesClosed: eyesClosed,
      smiling: smile > 0.5,
      leftEyeOpenProbability: left,
      rightEyeOpenProbability: right,
      classificationAvailable: classificationReady,
      minFaceWidthRequiredPx: kAndroidMinFaceWidthForCapturePx,
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
