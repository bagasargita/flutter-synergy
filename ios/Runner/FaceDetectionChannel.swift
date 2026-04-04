import CoreImage
import CoreVideo
import Flutter
import UIKit
import Vision

/// Apple Vision face landmarks on the same binary messenger as the implicit Flutter
/// engine ([FlutterImplicitEngineDelegate]).
///
/// Supports file-based analysis plus **BGRA preview frames** (no photo shutter) and
/// writing a JPEG from the last BGRA frame for a silent final image.
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
    case "analyzeBgraFrame":
      guard let args = call.arguments as? [String: Any],
            let w = args["width"] as? Int,
            let h = args["height"] as? Int,
            let row = args["bytesPerRow"] as? Int,
            let typed = args["bytes"] as? FlutterStandardTypedData else {
        result(FlutterError(code: "bad_args", message: "BGRA frame args", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let payload = Self.analyzeBgra(
          data: typed.data, width: w, height: h, bytesPerRow: row)
        DispatchQueue.main.async {
          result(payload)
        }
      }
    case "writeBgraJpegTemp":
      guard let args = call.arguments as? [String: Any],
            let w = args["width"] as? Int,
            let h = args["height"] as? Int,
            let row = args["bytesPerRow"] as? Int,
            let typed = args["bytes"] as? FlutterStandardTypedData else {
        result(FlutterError(code: "bad_args", message: "BGRA jpeg args", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let path = Self.writeBgraJpegTemp(data: typed.data, width: w, height: h, bytesPerRow: row)
        DispatchQueue.main.async {
          result(path)
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
    return runLandmarks(handler: handler, pixelWidth: CGFloat(cgImage.width), pixelHeight: CGFloat(cgImage.height))
  }

  /// Flutter’s video stream delivers the front camera buffer in sensor layout (often **landscape**
  /// pixels while the app is portrait). Still JPEGs carry EXIF orientation; raw BGRA does not, so
  /// Vision must be told how to read the buffer or landmarks (and eye spans) are wrong.
  private static func bgraVisionOrientation(width: Int, height: Int) -> CGImagePropertyOrientation {
    if width > height {
      return .rightMirrored
    }
    return .upMirrored
  }

  private static func analyzeBgra(data: Data, width: Int, height: Int, bytesPerRow: Int) -> [String: Any] {
    guard let buffer = makeBGRAPixelBuffer(data: data, width: width, height: height, bytesPerRow: bytesPerRow)
    else {
      return ["faceCount": 0, "classificationAvailable": false]
    }
    let orientation = bgraVisionOrientation(width: width, height: height)
    let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: orientation, options: [:])
    return runLandmarks(handler: handler, pixelWidth: CGFloat(width), pixelHeight: CGFloat(height))
  }

  private static func runLandmarks(
    handler: VNImageRequestHandler,
    pixelWidth: CGFloat,
    pixelHeight: CGFloat
  ) -> [String: Any] {
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
    let w = pixelWidth
    let h = pixelHeight

    let box = face.boundingBox
    let pixelLeft = box.origin.x * w
    let pixelWidth = box.size.width * w
    let pixelHeight = box.size.height * h
    let pixelTop = (1.0 - box.origin.y - box.size.height) * h

    let landmarks = face.landmarks
    let leftOpen = eyeOpennessHeuristic(landmarks?.leftEye)
    let rightOpen = eyeOpennessHeuristic(landmarks?.rightEye)
    // Closed eyes often drop eye contours; requiring both regions made
    // `classificationAvailable` false and the Flutter eye-liveness loop stuck on
    // “Hold still…”. Missing regions → 0 from heuristic.
    return [
      "faceCount": 1,
      "bounds": [pixelLeft, pixelTop, pixelWidth, pixelHeight],
      "leftEyeOpen": leftOpen,
      "rightEyeOpen": rightOpen,
      "classificationAvailable": true,
    ]
  }

  /// Eye “openness” from landmark spread. Uses **min**(H, V): closed lids collapse one axis
  /// (often vertical) while max(H,V) can stay large along the lash line — that made shut eyes
  /// look “open” to Flutter.
  private static func eyeOpennessHeuristic(_ region: VNFaceLandmarkRegion2D?) -> Double {
    guard let region = region, region.pointCount > 1 else { return 0 }
    let pts = region.normalizedPoints
    var minX = CGFloat.greatestFiniteMagnitude
    var maxX = -CGFloat.greatestFiniteMagnitude
    var minY = CGFloat.greatestFiniteMagnitude
    var maxY = -CGFloat.greatestFiniteMagnitude
    for i in 0..<region.pointCount {
      let p = pts[i]
      let x = CGFloat(p.x)
      let y = CGFloat(p.y)
      minX = min(minX, x)
      maxX = max(maxX, x)
      minY = min(minY, y)
      maxY = max(maxY, y)
    }
    let spanH = max(0, maxX - minX)
    let spanV = max(0, maxY - minY)
    let span = min(spanH, spanV)
    return Double(min(1, span / 0.055))
  }

  private static func makeBGRAPixelBuffer(
    data: Data,
    width: Int,
    height: Int,
    bytesPerRow: Int
  ) -> CVPixelBuffer? {
    var buffer: CVPixelBuffer?
    let attrs: [String: Any] = [
      kCVPixelBufferCGImageCompatibilityKey as String: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
      kCVPixelBufferBytesPerRowAlignmentKey as String: bytesPerRow,
    ]
    let status = CVPixelBufferCreate(
      kCFAllocatorDefault,
      width,
      height,
      kCVPixelFormatType_32BGRA,
      attrs as CFDictionary,
      &buffer
    )
    guard status == kCVReturnSuccess, let buf = buffer else { return nil }

    CVPixelBufferLockBaseAddress(buf, [])
    defer { CVPixelBufferUnlockBaseAddress(buf, []) }

    guard let destBase = CVPixelBufferGetBaseAddress(buf) else { return nil }
    let destRow = CVPixelBufferGetBytesPerRow(buf)
    let destPtr = destBase.assumingMemoryBound(to: UInt8.self)

    data.withUnsafeBytes { raw in
      guard let srcBase = raw.bindMemory(to: UInt8.self).baseAddress else { return }
      let rowCopy = min(bytesPerRow, destRow)
      for y in 0..<height {
        memcpy(destPtr + y * destRow, srcBase + y * bytesPerRow, rowCopy)
      }
    }
    return buf
  }

  private static func writeBgraJpegTemp(
    data: Data,
    width: Int,
    height: Int,
    bytesPerRow: Int
  ) -> String? {
    guard let buffer = makeBGRAPixelBuffer(data: data, width: width, height: height, bytesPerRow: bytesPerRow)
    else {
      return nil
    }
    let ciImage = CIImage(cvPixelBuffer: buffer)
    let context = CIContext(options: nil)
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
    let visionOrientation = bgraVisionOrientation(width: width, height: height)
    let uiOrientation = uiImageOrientation(from: visionOrientation)
    let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: uiOrientation)
    guard let jpeg = uiImage.jpegData(compressionQuality: 0.92) else { return nil }
    let dir = NSTemporaryDirectory()
    let name = "face_silent_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
    let path = (dir as NSString).appendingPathComponent(name)
    do {
      try jpeg.write(to: URL(fileURLWithPath: path))
      return path
    } catch {
      return nil
    }
  }

  private static func uiImageOrientation(from vision: CGImagePropertyOrientation) -> UIImage.Orientation {
    switch vision {
    case .up: return .up
    case .upMirrored: return .upMirrored
    case .down: return .down
    case .downMirrored: return .downMirrored
    case .left: return .left
    case .right: return .right
    case .leftMirrored: return .leftMirrored
    case .rightMirrored: return .rightMirrored
    @unknown default: return .up
    }
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
