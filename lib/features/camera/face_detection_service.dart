import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

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
  });

  final int faceCount;
  final Face? singleFace;
  final bool eyesOpen;

  /// True when both eyes are closed (for blink detection).
  final bool eyesClosed;
  final bool smiling;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;

  bool get hasSingleFace => faceCount == 1 && singleFace != null;
  bool get isGoodForCapture =>
      hasSingleFace && eyesOpen && singleFace!.boundingBox.width > 80;
}

/// Runs ML Kit face detection on an image file.
/// Uses classification (eyes open, smiling) for liveness.
class FaceDetectionService {
  FaceDetectionService() : _detector = _createDetector();

  static FaceDetector _createDetector() {
    return FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: false,
        enableContours: false,
        enableTracking: false,
        minFaceSize: 0.15,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
  }

  final FaceDetector _detector;

  Future<FaceDetectionResult> processFile(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final faces = await _detector.processImage(inputImage);

    if (faces.isEmpty) {
      return const FaceDetectionResult(faceCount: 0);
    }
    if (faces.length > 1) {
      return FaceDetectionResult(faceCount: faces.length);
    }

    final face = faces.first;
    final left = face.leftEyeOpenProbability ?? 0;
    final right = face.rightEyeOpenProbability ?? 0;
    final smile = face.smilingProbability ?? 0;

    return FaceDetectionResult(
      faceCount: 1,
      singleFace: face,
      eyesOpen: left > 0.4 && right > 0.4,
      eyesClosed: left < 0.35 && right < 0.35,
      smiling: smile > 0.5,
      leftEyeOpenProbability: left,
      rightEyeOpenProbability: right,
    );
  }

  Future<void> close() => _detector.close();
}
