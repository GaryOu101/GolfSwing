import Foundation

protocol SwingAnalysisService {
    func analyze(videoURL: URL, profile: BodyProfileSnapshot?) async throws -> SwingAnalysis
}

/// Fake results so the whole app flow works before the ML backend exists.
/// Shows the core idea: targets come from the golfer's own body profile.
struct MockSwingAnalysisService: SwingAnalysisService {
    func analyze(videoURL: URL, profile: BodyProfileSnapshot?) async throws -> SwingAnalysis {
        try await Task.sleep(for: .seconds(1.5))

        let shoulderTurn = Double.random(in: 60...100)
        let hipTurn = Double.random(in: 30...55)
        let headSway = Double.random(in: 1...9)
        let tempo = Double.random(in: 2.4...3.6)

        // Personalized target: never ask for more turn than the screen says the golfer has.
        let shoulderTarget = min(profile?.trunkRotationDegrees ?? 90, 90)

        var faults: [SwingFault] = []
        if shoulderTurn < shoulderTarget - 10 {
            faults.append(SwingFault(
                title: "Incomplete shoulder turn",
                detail: "You turned \(Int(shoulderTurn))°, but your assessment shows you can reach about \(Int(shoulderTarget))°."))
        }
        if headSway > 5 {
            faults.append(SwingFault(
                title: "Head movement",
                detail: "Your head moved about \(Int(headSway)) cm during the backswing. Aim for under 5 cm."))
        }
        if profile?.grip == .strong {
            faults.append(SwingFault(
                title: "Grip note",
                detail: "With a strong grip, focus on body rotation through impact rather than rolling your forearms."))
        }

        return SwingAnalysis(
            tempoRatio: tempo,
            metrics: [
                SwingMetric(name: "Shoulder turn", value: shoulderTurn, unit: "°"),
                SwingMetric(name: "Hip turn", value: hipTurn, unit: "°"),
                SwingMetric(name: "Head sway", value: headSway, unit: "cm"),
            ],
            faults: faults,
            isMock: true)
    }
}

/// Uploads the video + profile to the FastAPI backend in /server.
struct RemoteSwingAnalysisService: SwingAnalysisService {
    let baseURL: URL

    func analyze(videoURL: URL, profile: BodyProfileSnapshot?) async throws -> SwingAnalysis {
        var request = URLRequest(url: baseURL.appending(path: "analyze"))
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func append(_ string: String) { body.append(Data(string.utf8)) }

        if let profile, let json = try? JSONEncoder().encode(profile) {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"profile\"\r\n\r\n")
            body.append(json)
            append("\r\n")
        }
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"video\"; filename=\"\(videoURL.lastPathComponent)\"\r\n")
        append("Content-Type: video/quicktime\r\n\r\n")
        body.append(try Data(contentsOf: videoURL))
        append("\r\n--\(boundary)--\r\n")

        let (data, response) = try await URLSession.shared.upload(for: request, from: body)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(SwingAnalysis.self, from: data)
    }
}
