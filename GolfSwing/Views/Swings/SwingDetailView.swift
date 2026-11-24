import AVKit
import SwiftUI

struct SwingDetailView: View {
    let swing: SwingRecord
    @State private var player: AVPlayer?

    var body: some View {
        List {
            Section {
                VideoPlayer(player: player)
                    .frame(height: 360)
                    .listRowInsets(EdgeInsets())
            }

            switch swing.status {
            case .analyzing:
                Section { ProgressView("Analyzing swing…") }
            case .failed:
                Section {
                    Label("Analysis failed. Check the backend connection.", systemImage: "exclamationmark.triangle")
                }
            case .complete:
                if let analysis = swing.analysis {
                    Section {
                        LabeledContent("Tempo", value: String(format: "%.1f : 1", analysis.tempoRatio))
                        ForEach(analysis.metrics) { metric in
                            LabeledContent(metric.name, value: String(format: "%.0f %@", metric.value, metric.unit))
                        }
                    } header: {
                        Text("Metrics")
                    } footer: {
                        if analysis.isMock { Text("Demo data from the mock analysis service.") }
                    }

                    Section("Feedback") {
                        if analysis.faults.isEmpty {
                            Text("No issues found for your body profile.")
                        }
                        ForEach(analysis.faults) { fault in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fault.title).font(.headline)
                                Text(fault.detail).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Swing")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { player = AVPlayer(url: VideoStorage.url(for: swing.videoFileName)) }
        .onDisappear { player?.pause() }
    }
}
