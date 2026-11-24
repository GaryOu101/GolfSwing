import SwiftUI
import SwiftData

/// Onboarding screen: grip photo + mobility tests, saved as a BodyProfile.
struct AssessmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var grip: GripType = .unknown
    @State private var trunkRotation: Double?
    @State private var pelvicRotation: Double?
    @State private var toeTouch = false

    var body: some View {
        List {
            Section("1. Grip") {
                NavigationLink {
                    GripCaptureView(grip: $grip)
                } label: {
                    row("Grip photo", value: grip == .unknown ? nil : grip.label)
                }
            }

            Section {
                NavigationLink {
                    MobilityTestView(test: .trunkRotation, result: $trunkRotation)
                } label: {
                    row(MobilityTest.trunkRotation.title, value: trunkRotation.map { "\(Int($0))°" })
                }
                NavigationLink {
                    MobilityTestView(test: .pelvicRotation, result: $pelvicRotation)
                } label: {
                    row(MobilityTest.pelvicRotation.title, value: pelvicRotation.map { "\(Int($0))°" })
                }
                Toggle("Can touch toes with straight legs", isOn: $toeTouch)
            } header: {
                Text("2. Mobility")
            } footer: {
                Text("Keep the phone at the same distance for each test. Rotation is estimated from the camera, so treat numbers as approximate.")
            }

            Section {
                Button("Save profile", action: save)
                    .disabled(grip == .unknown && trunkRotation == nil && pelvicRotation == nil)
            }
        }
        .navigationTitle("Assessment")
    }

    private func row(_ title: String, value: String?) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value ?? "Not done")
                .foregroundStyle(value == nil ? .secondary : .primary)
        }
    }

    private func save() {
        let profile = BodyProfile(grip: grip,
                                  trunkRotationDegrees: trunkRotation,
                                  pelvicRotationDegrees: pelvicRotation,
                                  toeTouchPassed: toeTouch)
        modelContext.insert(profile)
        dismiss()
    }
}
