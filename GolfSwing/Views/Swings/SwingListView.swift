import SwiftUI
import SwiftData

struct SwingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SwingRecord.createdAt, order: .reverse) private var swings: [SwingRecord]
    @Query(sort: \BodyProfile.createdAt, order: .reverse) private var profiles: [BodyProfile]

    @State private var pickerSource: PickerSource?
    @State private var errorMessage: String?

    enum PickerSource: String, Identifiable {
        case camera, library
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            List {
                if swings.isEmpty {
                    ContentUnavailableView("No swings yet",
                                           systemImage: "video",
                                           description: Text("Record a swing from down-the-line or face-on."))
                }
                ForEach(swings) { swing in
                    NavigationLink {
                        SwingDetailView(swing: swing)
                    } label: {
                        SwingRow(swing: swing)
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Swings")
            .toolbar {
                Menu {
                    Button("Record swing", systemImage: "video") { pickerSource = .camera }
                    Button("Import video", systemImage: "photo.on.rectangle") { pickerSource = .library }
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(item: $pickerSource) { source in
                MediaPicker(kind: .video, source: source == .camera ? .camera : .photoLibrary) { result in
                    if case .video(let url) = result { addSwing(from: url) }
                }
                .ignoresSafeArea()
            }
            .alert("Something went wrong",
                   isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func addSwing(from url: URL) {
        do {
            let fileName = try VideoStorage.save(url)
            let record = SwingRecord(videoFileName: fileName)
            modelContext.insert(record)

            let snapshot = profiles.first.map(BodyProfileSnapshot.init(profile:))
            let videoURL = VideoStorage.url(for: fileName)
            Task { @MainActor in
                do {
                    record.analysis = try await AppServices.analysis.analyze(videoURL: videoURL, profile: snapshot)
                    record.status = .complete
                } catch {
                    record.status = .failed
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let swing = swings[index]
            VideoStorage.delete(swing.videoFileName)
            modelContext.delete(swing)
        }
    }
}

struct SwingRow: View {
    let swing: SwingRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(swing.createdAt.formatted(date: .abbreviated, time: .shortened))
                if let analysis = swing.analysis {
                    Text("Tempo \(analysis.tempoRatio, specifier: "%.1f"):1 · \(analysis.faults.count) note(s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            switch swing.status {
            case .analyzing: ProgressView()
            case .complete: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            case .failed: Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            }
        }
    }
}
