import Flutter
import UIKit
import Vision

/// Apple Vision face landmarks. Registered on the engine binary messenger so it
/// works with Flutter's implicit engine (not only `registrar(forPlugin:)`).
@objc(FaceDetectionChannel)
final class FaceDetectionChannel: NSObject {
  private static var methodChannel: FlutterMethodChannel?
  private static var retained: FaceDetectionChannel?

  static func register(with messenger: FlutterBinaryMessenger) {
    retained = FaceDetectionChannel()
    let channel = FlutterMethodChannel(
      name: "com.synergy.flutter_synergy/vision_face",
      binaryMessenger: messenger
    )
    methodChannel = channel
    let handler = retained!
    channel.setMethodCallHandler { call, result in
      handler.handle(call, result: result)
    }
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "analyzeStillImage":
      guard let args = call.arguments as? [String: Any],
            let path = args["path"] as? String else {
        result(
          FlutterError(code: "bad_args", message: "Expected {path: String}", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let payload = Self.analyzeStillImage(path: path)
        DispatchQueue.main.async {
          result(payload)
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func analyzeStillImage(path: String) -> [String: Any] {
    guard let image = UIImage(contentsOfFile: path), let cgImage = image.cgImage else {
      return ["faceCount": 0, "classificationAvailable": false]
    }

    let orientation = cgImageOrientation(from: image)
    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

    let landmarksRequest = VNDetectFaceLandmarksRequest()
    if #available(iOS 14.0, *) {
      landmarksRequest.revision = VNDetectFaceLandmarksRequestRevision3
    }

    do {
      try handler.perform([landmarksRequest])
    } catch {
      return ["faceCount": 0, "classificationAvailable": false, "error": error.localizedDescription]
    }

    guard let observations = landmarksRequest.results as? [VNFaceObservation], !observations.isEmpty
    else {
      return ["faceCount": 0, "classificationAvailable": false]
    }

    if observations.count > 1 {
      return ["faceCount": observations.count, "classificationAvailable": false]
    }

    let face = observations[0]
    let w = CGFloat(cgImage.width)
    let h = CGFloat(cgImage.height)

    let box = face.boundingBox
    let pixelLeft = box.origin.x * w
    let pixelWidth = box.size.width * w
    let pixelHeight = box.size.height * h
    let pixelTop = (1.0 - box.origin.y - box.size.height) * h

    let landmarks = face.landmarks
    let leftOpen = eyeOpennessHeuristic(landmarks?.leftEye)
    let rightOpen = eyeOpennessHeuristic(landmarks?.rightEye)
    let hasEyes = landmarks?.leftEye != nil && landmarks?.rightEye != nil

    return [
      "faceCount": 1,
      "bounds": [pixelLeft, pixelTop, pixelWidth, pixelHeight],
      "leftEyeOpen": leftOpen,
      "rightEyeOpen": rightOpen,
      "classificationAvailable": hasEyes,
    ]
  }

  private static func eyeOpennessHeuristic(_ region: VNFaceLandmarkRegion2D?) -> Double {
    guard let region = region, region.pointCount > 1 else { return 0 }
    let pts = region.normalizedPoints
    var minY = CGFloat.greatestFiniteMagnitude
    var maxY = -CGFloat.greatestFiniteMagnitude
    for i in 0..<region.pointCount {
      let p = pts[i]
      minY = min(minY, CGFloat(p.y))
      maxY = max(maxY, CGFloat(p.y))
    }
    let span = max(0, maxY - minY)
    return Double(min(1, span / 0.18))
  }

  private static func cgImageOrientation(from image: UIImage) -> CGImagePropertyOrientation {
    switch image.imageOrientation {
    case .up: return .up
    case .down: return .down
    case .left: return .left
    case .right: return .right
    case .upMirrored: return .upMirrored
    case .downMirrored: return .downMirrored
    case .leftMirrored: return .leftMirrored
    case .rightMirrored: return .rightMirrored
    @unknown default: return .up
    }
  }
}
