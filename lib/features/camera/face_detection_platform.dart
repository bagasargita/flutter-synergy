import 'dart:typed_data';

import 'package:flutter_synergy/features/camera/face_detection_types.dart';

/// Platform-specific face pipeline (ML Kit on Android, Vision on iOS).
abstract class FaceDetectionPlatform {
  Future<FaceDetectionResult> processFile(String path);

  /// iOS: Vision on a BGRA preview buffer (no [takePicture] / shutter). Other
  /// platforms return [Future.value(null)].
  Future<FaceDetectionResult?> processBgra8888Preview({
    required Uint8List bytes,
    required int width,
    required int height,
    required int bytesPerRow,
  });

  Future<void> close();
}
