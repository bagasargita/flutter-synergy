import 'dart:ui' show Rect;

import 'package:flutter_synergy/features/camera/face_detection_types.dart';

enum CameraVerificationMode { onePersonNod }

final class HeadNodVerificationParams {
  const HeadNodVerificationParams({
    required this.requiredConsecutiveSingleFaceFrames,
    required this.requiredBaselineFrames,
    required this.requiredNodUpRatio,
    required this.requiredNodDownRatio,
    required this.minFaceWidthPx,
  });

  final int requiredConsecutiveSingleFaceFrames;
  final int requiredBaselineFrames;
  final double requiredNodUpRatio;
  final double requiredNodDownRatio;
  final double minFaceWidthPx;

  factory HeadNodVerificationParams.forPlatform({required bool isIos}) {
    return HeadNodVerificationParams(
      requiredConsecutiveSingleFaceFrames: isIos ? 1 : 2,
      requiredBaselineFrames: isIos ? 2 : 3,
      requiredNodUpRatio: 0.12,
      requiredNodDownRatio: 0.10,
      minFaceWidthPx: isIos
          ? kIosMinFaceWidthForCapturePx
          : kAndroidMinFaceWidthForCapturePx,
    );
  }
}

enum HeadNodPhase { waitingBaseline, waitingNodUp, waitingNodDown, verified }

final class HeadNodUpdate {
  const HeadNodUpdate({
    required this.phase,
    required this.message,
    required this.verified,
  });

  final HeadNodPhase phase;
  final String message;
  final bool verified;
}

final class HeadNodVerifier {
  HeadNodVerifier(this.params);

  final HeadNodVerificationParams params;
  double _baselineCenterY = 0;
  int _baselineSamples = 0;
  double _bestUpRatio = 0;
  HeadNodPhase _phase = HeadNodPhase.waitingBaseline;

  void reset() {
    _baselineCenterY = 0;
    _baselineSamples = 0;
    _bestUpRatio = 0;
    _phase = HeadNodPhase.waitingBaseline;
  }

  bool canStart(FaceDetectionResult result) {
    final box = result.effectiveFaceBounds;
    return result.faceCount == 1 &&
        box != null &&
        box.width >= params.minFaceWidthPx;
  }

  HeadNodUpdate start() {
    reset();
    return const HeadNodUpdate(
      phase: HeadNodPhase.waitingBaseline,
      message: 'Hold still — preparing nod verification',
      verified: false,
    );
  }

  HeadNodUpdate next(FaceDetectionResult result) {
    final box = result.effectiveFaceBounds;
    if (result.faceCount == 0 || box == null) {
      return HeadNodUpdate(
        phase: _phase,
        message: 'Position your face in the frame',
        verified: false,
      );
    }
    if (result.faceCount > 1) {
      return HeadNodUpdate(
        phase: _phase,
        message: 'Only one person should be in frame',
        verified: false,
      );
    }
    if (box.width < params.minFaceWidthPx) {
      return HeadNodUpdate(
        phase: _phase,
        message: 'Move a little closer to the camera',
        verified: false,
      );
    }
    return _nextForSingleFace(box);
  }

  HeadNodUpdate _nextForSingleFace(Rect box) {
    final centerY = box.center.dy;
    final faceHeight = box.height <= 1 ? 1.0 : box.height;

    if (_phase == HeadNodPhase.waitingBaseline) {
      _baselineCenterY =
          ((_baselineCenterY * _baselineSamples) + centerY) / (_baselineSamples + 1);
      _baselineSamples++;
      if (_baselineSamples < params.requiredBaselineFrames) {
        return const HeadNodUpdate(
          phase: HeadNodPhase.waitingBaseline,
          message: 'Hold still — preparing nod verification',
          verified: false,
        );
      }
      _phase = HeadNodPhase.waitingNodUp;
      return const HeadNodUpdate(
        phase: HeadNodPhase.waitingNodUp,
        message: 'Nod your head up',
        verified: false,
      );
    }

    final offsetRatio = (centerY - _baselineCenterY) / faceHeight;
    final upRatio = -offsetRatio;
    if (_phase == HeadNodPhase.waitingNodUp) {
      if (upRatio > _bestUpRatio) {
        _bestUpRatio = upRatio;
      }
      if (_bestUpRatio >= params.requiredNodUpRatio) {
        _phase = HeadNodPhase.waitingNodDown;
        return const HeadNodUpdate(
          phase: HeadNodPhase.waitingNodDown,
          message: 'Now nod your head down',
          verified: false,
        );
      }
      return const HeadNodUpdate(
        phase: HeadNodPhase.waitingNodUp,
        message: 'Nod your head up',
        verified: false,
      );
    }

    if (_phase == HeadNodPhase.waitingNodDown) {
      if (offsetRatio >= params.requiredNodDownRatio) {
        _phase = HeadNodPhase.verified;
        return const HeadNodUpdate(
          phase: HeadNodPhase.verified,
          message: 'Verification complete',
          verified: true,
        );
      }
      return const HeadNodUpdate(
        phase: HeadNodPhase.waitingNodDown,
        message: 'Now nod your head down',
        verified: false,
      );
    }

    return const HeadNodUpdate(
      phase: HeadNodPhase.verified,
      message: 'Verification complete',
      verified: true,
    );
  }
}
