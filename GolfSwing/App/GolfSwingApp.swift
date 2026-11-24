import SwiftUI
import SwiftData

@main
struct GolfSwingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [BodyProfile.self, SwingRecord.self])
    }
}

/// Central place to swap implementations (mock vs. real backend).
enum AppServices {
    static let analysis: SwingAnalysisService = MockSwingAnalysisService()
    // When the Python backend is running, switch to:
    // static let analysis: SwingAnalysisService = RemoteSwingAnalysisService(
    //     baseURL: URL(string: "http://192.168.1.10:8000")!)
}
