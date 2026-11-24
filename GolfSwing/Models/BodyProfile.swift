import Foundation
import SwiftData

enum GripType: String, Codable, CaseIterable, Identifiable {
    case unknown, weak, neutral, strong
    var id: String { rawValue }
    var label: String { self == .unknown ? "Not set" : rawValue.capitalized }
}

/// The golfer's physical capabilities, measured during the assessment.
@Model
final class BodyProfile {
    var createdAt: Date
    var gripRaw: String
    var trunkRotationDegrees: Double?
    var pelvicRotationDegrees: Double?
    var toeTouchPassed: Bool

    init(grip: GripType,
         trunkRotationDegrees: Double?,
         pelvicRotationDegrees: Double?,
         toeTouchPassed: Bool) {
        self.createdAt = .now
        self.gripRaw = grip.rawValue
        self.trunkRotationDegrees = trunkRotationDegrees
        self.pelvicRotationDegrees = pelvicRotationDegrees
        self.toeTouchPassed = toeTouchPassed
    }

    var grip: GripType {
        get { GripType(rawValue: gripRaw) ?? .unknown }
        set { gripRaw = newValue.rawValue }
    }
}

/// Plain value copy of a profile, safe to send to services / the backend.
struct BodyProfileSnapshot: Codable {
    var grip: GripType
    var trunkRotationDegrees: Double?
    var pelvicRotationDegrees: Double?
    var toeTouchPassed: Bool

    init(profile: BodyProfile) {
        grip = profile.grip
        trunkRotationDegrees = profile.trunkRotationDegrees
        pelvicRotationDegrees = profile.pelvicRotationDegrees
        toeTouchPassed = profile.toeTouchPassed
    }
}
