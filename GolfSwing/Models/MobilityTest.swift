import Foundation
import Vision

/// Camera-based rotation tests. Each measures how much a pair of joints
/// "narrows" on screen as the golfer rotates away from the camera.
enum MobilityTest: String, CaseIterable, Identifiable {
    case trunkRotation, pelvicRotation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .trunkRotation: "Trunk rotation"
        case .pelvicRotation: "Pelvic rotation"
        }
    }

    var instructions: String {
        switch self {
        case .trunkRotation:
            "Face the camera in golf posture, arms crossed on your chest. Tap Set baseline, then turn your shoulders as far as you can while keeping your hips still."
        case .pelvicRotation:
            "Face the camera in golf posture. Tap Set baseline, then rotate your hips as far as you can while keeping your shoulders still."
        }
    }

    var jointPair: (VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName) {
        switch self {
        case .trunkRotation: (.leftShoulder, .rightShoulder)
        case .pelvicRotation: (.leftHip, .rightHip)
        }
    }
}
