# GolfSwing starter app

SwiftUI iOS 17+ app: a body-profile assessment (grip + mobility), then swing recording with analysis personalized to that profile.

## Run it

1. Install XcodeGen: `brew install xcodegen`
2. In this folder run `xcodegen`, then open `GolfSwing.xcodeproj`
3. Select your team under Signing & Capabilities
4. Run on a **real iPhone**. The Simulator has no camera, though importing videos from the library works there.

No XcodeGen? Create a new iOS App project in Xcode (SwiftUI, SwiftData), delete its generated Swift files, drag in the `GolfSwing/` folder, and add the camera, microphone, and photo library usage descriptions from `project.yml` to the target's Info tab.

## What works now

| Feature | Status |
|---|---|
| Tab app: Profile + Swings, SwiftData persistence | Working |
| Grip photo + on-device hand detection (Vision) | Working; grip label is manual |
| Trunk/pelvic rotation test with live skeleton overlay | Working; rough foreshortening estimate |
| Record or import swing video, playback | Working |
| Swing analysis | Mock service with profile-based targets |
| Upload to backend | `RemoteSwingAnalysisService` + `server/main.py` stub |

## Structure

```
GolfSwing/
  App/        entry point, tabs, AppServices (swap mock <-> backend)
  Models/     BodyProfile, SwingRecord/SwingAnalysis, MobilityTest
  Services/   PoseDetector, CameraPoseModel, SwingAnalysisService, VideoStorage
  Views/      Profile (assessment, grip, mobility), Swings (list, detail), Shared (camera, picker)
server/       FastAPI stub with the same JSON contract
```

## Backend

```
cd server
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

Then in `GolfSwingApp.swift`, switch `AppServices.analysis` to `RemoteSwingAnalysisService` with your Mac's LAN IP. Plain `http` to a LAN IP may need an App Transport Security exception (`NSAllowsLocalNetworking`).

## Next steps

1. Validate the rotation test against a goniometer and record the error.
2. Replace the system camera with a custom AVCaptureSession recorder at 120–240 fps.
3. Build the real pipeline in `server/main.py` (MediaPipe, swing phases, metrics).
4. Train a grip classifier on the photos you label in the app.
