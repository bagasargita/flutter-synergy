import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_synergy/features/camera/face_detection_platform.dart';
import 'package:flutter_synergy/features/camera/face_detection_types.dart';

/// iOS: Apple Vision via method channel. Supports **BGRA preview** (silent) and file stills.
final class FaceDetectionServiceIos implements FaceDetectionPlatform {
  static const MethodChannel _visionChannel = MethodChannel(
    'com.synergy.flutter_synergy/vision_face',
  );

  /// Maps Vision openness scores to [eyesOpen] / [eyesClosed]. After Swift switched to
  /// min(H,V) span, shut lids score lower; keep closed detection sensitive.
  static (bool open, bool closed) _iosLenientEyePair(double left, double right) {
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
    final resolvedPath =
        path.startsWith('file://') ? Uri.parse(path).toFilePath() : path;
    await _waitForCaptureFile(resolvedPath);

    try {
      final raw = await _visionChannel.invokeMethod<dynamic>('analyzeStillImage', {
        'path': resolvedPath,
      });
      return _resultFromVisionPayload(raw);
    } on MissingPluginException catch (e, st) {
      if (kDebugMode) {
        debugPrint('FaceDetectionServiceIos: Vision channel missing — $e\n$st');
      }
      return const FaceDetectionResult(
        faceCount: 0,
        minFaceWidthRequiredPx: kIosMinFaceWidthForCapturePx,
      );
    } on PlatformException catch (e, st) {
      if (kDebugMode) {
        debugPrint('FaceDetectionServiceIos: $e\n$st');
      }
      return const FaceDetectionResult(
        faceCount: 0,
        minFaceWidthRequiredPx: kIosMinFaceWidthForCapturePx,
      );
    }
  }

  @override
  Future<FaceDetectionResult?> processBgra8888Preview({
    required Uint8List bytes,
    required int width,
    required int height,
    required int bytesPerRow,
  }) async {
    try {
      final raw = await _visionChannel.invokeMethod<dynamic>('analyzeBgraFrame', {
        'width': width,
        'height': height,
        'bytesPerRow': bytesPerRow,
        'bytes': bytes,
      });
      return _resultFromVisionPayload(raw);
    } on PlatformException catch (e, st) {
      if (kDebugMode) {
        debugPrint('FaceDetectionServiceIos analyzeBgraFrame: $e\n$st');
      }
      return null;
    }
  }

  /// Silent JPEG path for the final attendance image (no photo capture).
  static Future<String?> writeBgraSnapshotToTempJpeg({
    required Uint8List bytes,
    required int width,
    required int height,
    required int bytesPerRow,
  }) async {
    try {
      return _visionChannel.invokeMethod<String>('writeBgraJpegTemp', {
        'width': width,
        'height': height,
        'bytesPerRow': bytesPerRow,
        'bytes': bytes,
      });
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('writeBgraJpegTemp: $e');
      }
      return null;
    }
  }

  FaceDetectionResult _resultFromVisionPayload(dynamic raw) {
    if (raw is! Map) {
      return const FaceDetectionResult(
        faceCount: 0,
        minFaceWidthRequiredPx: kIosMinFaceWidthForCapturePx,
      );
    }
    final map = Map<String, dynamic>.from(raw);

    final count = (map['faceCount'] as num?)?.toInt() ?? 0;
    if (count == 0) {
      return const FaceDetectionResult(
        faceCount: 0,
        minFaceWidthRequiredPx: kIosMinFaceWidthForCapturePx,
      );
    }
    if (count > 1) {
      return FaceDetectionResult(
        faceCount: count,
        minFaceWidthRequiredPx: kIosMinFaceWidthForCapturePx,
      );
    }

    final boundsRaw = map['bounds'];
    Rect? faceBounds;
    if (boundsRaw is List && boundsRaw.length == 4) {
      faceBounds = Rect.fromLTWH(
        (boundsRaw[0] as num).toDouble(),
        (boundsRaw[1] as num).toDouble(),
        (boundsRaw[2] as num).toDouble(),
        (boundsRaw[3] as num).toDouble(),
      );
    }

    final classReady = map['classificationAvailable'] == true;
    final left = (map['leftEyeOpen'] as num?)?.toDouble() ?? 0.0;
    final right = (map['rightEyeOpen'] as num?)?.toDouble() ?? 0.0;

    final bool eyesOpen;
    final bool eyesClosed;
    if (classReady) {
      final pair = _iosLenientEyePair(left, right);
      eyesOpen = pair.$1;
      eyesClosed = pair.$2;
    } else {
      eyesOpen = false;
      eyesClosed = false;
    }

    return FaceDetectionResult(
      faceCount: 1,
      faceBoundsImage: faceBounds,
      eyesOpen: eyesOpen,
      eyesClosed: eyesClosed,
      smiling: false,
      leftEyeOpenProbability: left,
      rightEyeOpenProbability: right,
      classificationAvailable: classReady,
      minFaceWidthRequiredPx: kIosMinFaceWidthForCapturePx,
    );
  }

  Future<void> _waitForCaptureFile(String path) async {
    final file = File(path);
    for (var i = 0; i < 24; i++) {
      if (file.existsSync()) {
        final len = file.lengthSync();
        if (len > 512) return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Future<void> close() async {}
}
