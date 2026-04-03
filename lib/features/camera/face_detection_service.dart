import 'dart:io';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Minimum detected face width (image pixels) before we treat framing as OK.
/// iOS front-camera + [ResolutionPreset.medium] often yields ~360–720px-wide
/// images; a fixed 80px bar rejected valid faces that ML Kit already accepted
/// via [FaceDetectorOptions.minFaceSize].
const double kMinFaceWidthForCapturePx = 48;

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

  bool get hasSingleFace => faceCount == 1 && singleFace != null;
  bool get isGoodForCapture =>
      hasSingleFace &&
      eyesOpen &&
      singleFace!.boundingBox.width >= kMinFaceWidthForCapturePx;
}

/// Runs ML Kit face detection on an image file.
/// Uses classification (eyes open, smiling) for liveness.
class FaceDetectionService {
  FaceDetectionService() : _detector = _createDetector();

  static FaceDetector _createDetector() {
    // iOS: FAST mode often omits or weakens eye/smile classification; ML Kit
    // documents richer attributes in ACCURATE mode. Android stays FAST for speed.
    final mode =
        Platform.isIOS ? FaceDetectorMode.accurate : FaceDetectorMode.fast;
    return FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: false,
        enableContours: false,
        enableTracking: false,
        minFaceSize: 0.12,
        performanceMode: mode,
      ),
    );
  }

  final FaceDetector _detector;

  Future<FaceDetectionResult> processFile(String path) async {
    if (Platform.isIOS) {
      final file = File(path);
      for (var i = 0; i < 8; i++) {
        if (file.existsSync() && file.lengthSync() > 0) break;
        await Future<void>.delayed(const Duration(milliseconds: 35));
      }
    }

    final inputImage = InputImage.fromFilePath(path);
    final faces = await _detector.processImage(inputImage);

    if (faces.isEmpty) {
      return const FaceDetectionResult(faceCount: 0);
    }
    if (faces.length > 1) {
      return FaceDetectionResult(faceCount: faces.length);
    }

    final face = faces.first;
    final left = face.leftEyeOpenProbability;
    final right = face.rightEyeOpenProbability;
    final smile = face.smilingProbability ?? 0;
    final classificationReady = left != null && right != null;

    // Do not coerce null → 0: that marks both eyes "closed" and blocks the flow.
    final bool eyesOpen;
    final bool eyesClosed;
    if (classificationReady) {
      eyesOpen = left > 0.4 && right > 0.4;
      eyesClosed = left < 0.35 && right < 0.35;
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
    );
  }

  Future<void> close() => _detector.close();
}
