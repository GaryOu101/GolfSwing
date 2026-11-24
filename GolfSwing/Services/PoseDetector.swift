import CoreGraphics
import CoreVideo
import UIKit
import Vision

/// One frame of body keypoints. Points are normalized (0...1) with a top-left origin.
struct BodyPose: Equatable {
    var joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    var imageSize: CGSize

    /// Pixel distance between two joints, or nil if either wasn't detected.
    func distance(_ a: VNHumanBodyPoseObservation.JointName,
                  _ b: VNHumanBodyPoseObservation.JointName) -> CGFloat? {
        guard let p1 = joints[a], let p2 = joints[b] else { return nil }
        let dx = (p1.x - p2.x) * imageSize.width
        let dy = (p1.y - p2.y) * imageSize.height
        return hypot(dx, dy)
    }
}

/// Wraps Apple Vision's on-device body pose model.
final class PoseDetector {
    private let request = VNDetectHumanBodyPoseRequest()
    var minimumConfidence: Float = 0.3

    func detect(in pixelBuffer: CVPixelBuffer,
                orientation: CGImagePropertyOrientation = .up) -> BodyPose? {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
        do { try handler.perform([request]) } catch { return nil }
        guard let observation = request.results?.first,
              let points = try? observation.recognizedPoints(.all) else { return nil }

        var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for (name, point) in points where point.confidence >= minimumConfidence {
            // Vision uses a bottom-left origin; flip to top-left for drawing.
            joints[name] = CGPoint(x: point.location.x, y: 1 - point.location.y)
        }
        let size = CGSize(width: CVPixelBufferGetWidth(pixelBuffer),
                          height: CVPixelBufferGetHeight(pixelBuffer))
        return BodyPose(joints: joints, imageSize: size)
    }
}

/// Estimates rotation from foreshortening: a joint pair that is W wide facing the
/// camera appears W·cos(θ) wide after rotating θ. Requires the golfer to stay at
/// the same distance from the camera. A rough first version to validate and improve.
enum RotationEstimator {
    static func degrees(currentWidth: CGFloat, baselineWidth: CGFloat) -> Double {
        guard baselineWidth > 0 else { return 0 }
        let ratio = min(1, max(0, Double(currentWidth / baselineWidth)))
        return acos(ratio) * 180 / .pi
    }
}

/// Hand detection for the grip photo. Grip classification itself is still manual.
enum HandDetector {
    static func countHands(in image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 2
        let handler = VNImageRequestHandler(cgImage: cgImage,
                                            orientation: CGImagePropertyOrientation(image.imageOrientation))
        try? handler.perform([request])
        return request.results?.count ?? 0
    }
}

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
