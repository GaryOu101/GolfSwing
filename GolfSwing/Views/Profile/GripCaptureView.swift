import SwiftUI

/// Grip step: take a close-up photo, check that hands are detected, label the grip.
/// Manual labels double as training data for an automatic grip classifier later.
struct GripCaptureView: View {
    @Binding var grip: GripType

    @State private var image: UIImage?
    @State private var showPicker = false
    @State private var handCount: Int?

    var body: some View {
        Form {
            Section {
                Text("Take a close-up of your hands at address from face-on. Count the knuckles visible on your lead hand: 1 is weak, 2 is neutral, 3 or more is strong.")
                    .font(.callout)
            }

            Section("Photo") {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                }
                Button(image == nil ? "Take grip photo" : "Retake photo") { showPicker = true }
                if let handCount {
                    Text(handCount > 0 ? "Detected \(handCount) hand(s)" : "No hands detected. Move closer and try again.")
                        .foregroundStyle(handCount > 0 ? .green : .orange)
                }
            }

            Section {
                Picker("Grip", selection: $grip) {
                    ForEach(GripType.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Grip strength")
            } footer: {
                Text("Automatic grip classification comes later.")
            }
        }
        .navigationTitle("Grip")
        .sheet(isPresented: $showPicker) {
            MediaPicker(kind: .photo) { result in
                if case .photo(let picked) = result {
                    image = picked
                    detectHands(in: picked)
                }
            }
            .ignoresSafeArea()
        }
    }

    private func detectHands(in picked: UIImage) {
        handCount = nil
        Task { @MainActor in
            handCount = await Task.detached { HandDetector.countHands(in: picked) }.value
        }
    }
}
