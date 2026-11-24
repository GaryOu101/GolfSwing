import SwiftUI

/// Live camera rotation test: set a facing-the-camera baseline, rotate, keep the max angle.
struct MobilityTestView: View {
    let test: MobilityTest
    @Binding var result: Double?

    @StateObject private var camera = CameraPoseModel(position: .front)
    @Environment(\.dismiss) private var dismiss

    @State private var baselineWidth: CGFloat?
    @State private var currentAngle: Double = 0
    @State private var maxAngle: Double = 0

    private var currentWidth: CGFloat? {
        let (a, b) = test.jointPair
        return camera.pose?.distance(a, b)
    }

    private var aspectRatio: CGFloat {
        guard let size = camera.pose?.imageSize, size.height > 0 else { return 9.0 / 16.0 }
        return size.width / size.height
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(test.instructions)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                Color.black
                CameraPreview(session: camera.session)
                PoseOverlay(pose: camera.pose)
                if let error = camera.errorMessage {
                    Text(error)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .aspectRatio(aspectRatio, contentMode: .fit)
            .frame(maxHeight: 420)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack {
                stat("Current", baselineWidth == nil ? "--" : "\(Int(currentAngle))°")
                stat("Max", baselineWidth == nil ? "--" : "\(Int(maxAngle))°")
            }

            HStack {
                Button("Set baseline") {
                    baselineWidth = currentWidth
                    currentAngle = 0
                    maxAngle = 0
                }
                .buttonStyle(.bordered)
                .disabled(currentWidth == nil)

                Button("Save \(Int(maxAngle))°") {
                    result = maxAngle
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(baselineWidth == nil || maxAngle == 0)
            }
        }
        .padding()
        .navigationTitle(test.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
        .onChange(of: camera.pose) { _, _ in updateAngle() }
    }

    private func updateAngle() {
        guard let baselineWidth, let width = currentWidth else { return }
        currentAngle = RotationEstimator.degrees(currentWidth: width, baselineWidth: baselineWidth)
        maxAngle = max(maxAngle, currentAngle)
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title.monospacedDigit().bold())
        }
        .frame(maxWidth: .infinity)
    }
}
