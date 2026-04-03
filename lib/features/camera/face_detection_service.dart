import 'dart:io';

export 'face_detection_platform.dart';
export 'face_detection_types.dart';

import 'package:flutter_synergy/features/camera/face_detection_android.dart';
import 'package:flutter_synergy/features/camera/face_detection_ios.dart';
import 'package:flutter_synergy/features/camera/face_detection_platform.dart';
import 'package:flutter_synergy/features/camera/face_detection_types.dart';

/// Face detection entry point: delegates to [FaceDetectionServiceIos] or
/// [FaceDetectionServiceAndroid].
final class FaceDetectionService {
  FaceDetectionService() : _platform = _createPlatform();

  final FaceDetectionPlatform _platform;

  static FaceDetectionPlatform _createPlatform() {
    if (Platform.isIOS) return FaceDetectionServiceIos();
    if (Platform.isAndroid) return FaceDetectionServiceAndroid();
    throw UnsupportedError(
      'Face detection is only implemented for iOS and Android.',
    );
  }

  Future<FaceDetectionResult> processFile(String path) =>
      _platform.processFile(path);

  Future<void> close() => _platform.close();
}
