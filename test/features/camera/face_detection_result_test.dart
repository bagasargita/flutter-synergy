import 'dart:ui';

import 'package:flutter_synergy/features/camera/face_detection_service.dart'
    show FaceDetectionResult, kAndroidMinFaceWidthForCapturePx;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFace extends Mock implements Face {}

void main() {
  group('FaceDetectionResult', () {
    test('hasSingleFace is true only when one face with payload exists', () {
      const noFace = FaceDetectionResult(faceCount: 0);
      const multiple = FaceDetectionResult(faceCount: 2);

      expect(noFace.hasSingleFace, isFalse);
      expect(multiple.hasSingleFace, isFalse);
    });

    test('isGoodForCapture requires single face, open eyes, and min size', () {
      final face = MockFace();
      when(
        () => face.boundingBox,
      ).thenReturn(const Rect.fromLTWH(0, 0, 120, 120));

      final result = FaceDetectionResult(
        faceCount: 1,
        singleFace: face,
        eyesOpen: true,
      );

      expect(result.hasSingleFace, isTrue);
      expect(result.isGoodForCapture, isTrue);
    });

    test('isGoodForCapture is false for small bounding box', () {
      final face = MockFace();
      when(() => face.boundingBox).thenReturn(
        Rect.fromLTWH(0, 0, kAndroidMinFaceWidthForCapturePx - 1, 120),
      );

      final result = FaceDetectionResult(
        faceCount: 1,
        singleFace: face,
        eyesOpen: true,
      );

      expect(result.isGoodForCapture, isFalse);
    });
  });
}
