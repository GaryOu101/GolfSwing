import Foundation
import SwiftData

enum SwingStatus: String, Codable {
    case analyzing, complete, failed
}

struct SwingMetric: Codable, Identifiable {
    var name: String
    var value: Double
    var unit: String
    var id: String { name }
}

struct SwingFault: Codable, Identifiable {
    var title: String
    var detail: String
    var id: String { title }
}

/// Result returned by an analysis service (mock or backend). Same JSON shape as server/main.py.
struct SwingAnalysis: Codable {
    var tempoRatio: Double
    var metrics: [SwingMetric]
    var faults: [SwingFault]
    var isMock: Bool
}

@Model
final class SwingRecord {
    var createdAt: Date
    var videoFileName: String
    var statusRaw: String
    var analysisJSON: Data?

    init(videoFileName: String) {
        self.createdAt = .now
        self.videoFileName = videoFileName
        self.statusRaw = SwingStatus.analyzing.rawValue
    }

    var status: SwingStatus {
        get { SwingStatus(rawValue: statusRaw) ?? .failed }
        set { statusRaw = newValue.rawValue }
    }

    var analysis: SwingAnalysis? {
        get { analysisJSON.flatMap { try? JSONDecoder().decode(SwingAnalysis.self, from: $0) } }
        set { analysisJSON = newValue.flatMap { try? JSONEncoder().encode($0) } }
    }
}
