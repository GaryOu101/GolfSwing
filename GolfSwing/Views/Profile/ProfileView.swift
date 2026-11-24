import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(sort: \BodyProfile.createdAt, order: .reverse) private var profiles: [BodyProfile]

    var body: some View {
        NavigationStack {
            List {
                if let profile = profiles.first {
                    Section("Your body profile") {
                        LabeledContent("Grip", value: profile.grip.label)
                        LabeledContent("Trunk rotation", value: format(profile.trunkRotationDegrees))
                        LabeledContent("Pelvic rotation", value: format(profile.pelvicRotationDegrees))
                        LabeledContent("Toe touch", value: profile.toeTouchPassed ? "Pass" : "Not yet")
                        LabeledContent("Assessed", value: profile.createdAt.formatted(date: .abbreviated, time: .omitted))
                    }
                } else {
                    ContentUnavailableView("No profile yet",
                                           systemImage: "figure.golf",
                                           description: Text("Take the 2-minute assessment so swing feedback fits your body."))
                }

                Section {
                    NavigationLink(profiles.isEmpty ? "Start assessment" : "Retake assessment") {
                        AssessmentView()
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }

    private func format(_ degrees: Double?) -> String {
        degrees.map { "\(Int($0.rounded()))°" } ?? "Not tested"
    }
}
