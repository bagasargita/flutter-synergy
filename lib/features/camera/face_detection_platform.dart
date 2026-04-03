import 'package:flutter_synergy/features/camera/face_detection_types.dart';

/// Platform-specific ML Kit pipeline (Android vs iOS).
abstract class FaceDetectionPlatform {
  Future<FaceDetectionResult> processFile(String path);
  Future<void> close();
}
