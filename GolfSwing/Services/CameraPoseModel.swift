import AVFoundation
import Combine

/// Live camera feed that runs pose detection on every frame.
final class CameraPoseModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var pose: BodyPose?
    @Published var errorMessage: String?

    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "camera.pose.queue")
    private let detector = PoseDetector()
    private var isConfigured = false
    private let position: AVCaptureDevice.Position

    init(position: AVCaptureDevice.Position = .front) {
        self.position = position
    }

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.startSession()
                } else {
                    DispatchQueue.main.async { self?.errorMessage = "Camera access was denied. Enable it in Settings." }
                }
            }
        default:
            errorMessage = "Camera access was denied. Enable it in Settings."
        }
    }

    func stop() {
        queue.async { [weak self] in self?.session.stopRunning() }
    }

    private func startSession() {
        queue.async { [weak self] in
            guard let self else { return }
            if !self.isConfigured { self.configure() }
            if self.isConfigured && !self.session.isRunning { self.session.startRunning() }
        }
    }

    private func configure() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            DispatchQueue.main.async { self.errorMessage = "Camera unavailable (the Simulator has no camera; run on a device)." }
            return
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)

        if let connection = output.connection(with: .video) {
            // Deliver portrait frames so Vision coordinates match the screen.
            if connection.isVideoRotationAngleSupported(90) { connection.videoRotationAngle = 90 }
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = (position == .front) // match the mirrored preview
            }
        }
        isConfigured = true
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let detected = detector.detect(in: buffer)
        DispatchQueue.main.async { self.pose = detected }
    }
}
