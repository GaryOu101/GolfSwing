import AVFoundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import Vision

/// Live camera preview.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

/// Draws the detected skeleton. Place it over a view with the same aspect ratio as the frame.
struct PoseOverlay: View {
    let pose: BodyPose?

    static let bones: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.leftShoulder, .rightShoulder), (.leftHip, .rightHip),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
        (.neck, .nose),
    ]

    var body: some View {
        Canvas { context, size in
            guard let pose else { return }
            func point(_ joint: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
                pose.joints[joint].map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
            }
            for (a, b) in Self.bones {
                guard let p1 = point(a), let p2 = point(b) else { continue }
                var path = Path()
                path.move(to: p1)
                path.addLine(to: p2)
                context.stroke(path, with: .color(.green), lineWidth: 3)
            }
            for joint in pose.joints.keys {
                guard let p = point(joint) else { continue }
                context.fill(Path(ellipseIn: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)),
                             with: .color(.yellow))
            }
        }
        .allowsHitTesting(false)
    }
}

enum MediaPickerResult {
    case photo(UIImage)
    case video(URL)
}

/// Camera / library picker for photos and videos. Falls back to the library
/// when no camera is available (e.g. the Simulator).
struct MediaPicker: UIViewControllerRepresentable {
    enum Kind { case photo, video }

    let kind: Kind
    var source: UIImagePickerController.SourceType = .camera
    let onPick: (MediaPickerResult) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(source) ? source : .photoLibrary
        switch kind {
        case .photo:
            picker.mediaTypes = [UTType.image.identifier]
        case .video:
            picker.mediaTypes = [UTType.movie.identifier]
            picker.videoQuality = .typeHigh
            if picker.sourceType == .camera { picker.cameraCaptureMode = .video }
        }
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: MediaPicker
        init(_ parent: MediaPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            // Handle synchronously: picker video URLs are temporary files.
            if let url = info[.mediaURL] as? URL {
                parent.onPick(.video(url))
            } else if let image = info[.originalImage] as? UIImage {
                parent.onPick(.photo(image))
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
