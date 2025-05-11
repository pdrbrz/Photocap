//
//  CameraService.swift
//  Photocap
//
//  Created by Pedro Braz on 11/05/25.
//

import AVFoundation
import UIKit

final class CameraService: NSObject, ObservableObject {
    @Published private(set) var currentPosition: AVCaptureDevice.Position = .back
    @Published var flashMode: AVCaptureDevice.FlashMode = .auto
    private(set) var session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var videoDevice: AVCaptureDevice?

    // callbacks
    var onPhotoCapture: ((UIImage) -> Void)?
    var onVideoCapture: ((URL) -> Void)?

    override init() {
        super.init()
        configureSession()
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Video input
        if let cam = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            videoDevice = cam
            if let videoIn = try? AVCaptureDeviceInput(device: cam),
               session.canAddInput(videoIn)
            {
                session.addInput(videoIn)
            }
            // lock fps to 30
            if cam.activeFormat.videoSupportedFrameRateRanges.first(where: { $0.maxFrameRate >= 60 }) != nil {
                try? cam.lockForConfiguration()
                cam.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
                cam.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
                cam.unlockForConfiguration()
            }
        }

        // Audio input (for movie)
        if let mic = AVCaptureDevice.default(for: .audio),
           let audioIn = try? AVCaptureDeviceInput(device: mic),
           session.canAddInput(audioIn)
        {
            session.addInput(audioIn)
        }

        // Photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        // Movie output
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }

        session.commitConfiguration()
    }

    func start() {
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        if session.isRunning {
            session.stopRunning()
        }
    }

    // PreviewLayer for SwiftUI
    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    /// Call this to flip between front/back
    func switchCamera() {
        guard let currentInput = session.inputs.first(where: { ($0 as? AVCaptureDeviceInput)?.device.hasMediaType(.video) == true }),
              let oldDeviceInput = currentInput as? AVCaptureDeviceInput else { return }

        let newPosition: AVCaptureDevice.Position = (oldDeviceInput.device.position == .back) ? .front : .back
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let newInput = try? AVCaptureDeviceInput(device: newDevice) else { return }

        session.beginConfiguration()
        session.removeInput(oldDeviceInput)
        if session.canAddInput(newInput) {
            session.addInput(newInput)
            currentPosition = newPosition
        }
        session.commitConfiguration()
    }

    /// Cycle flash between auto → on → off
    func toggleFlash() {
        switch flashMode {
        case .auto: flashMode = .on
        case .on: flashMode = .off
        case .off: flashMode = .auto
        @unknown default: flashMode = .auto
        }
    }
}

// MARK: - Photo capture

extension CameraService: AVCapturePhotoCaptureDelegate {
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        // only set it if that mode is supported
        if photoOutput.supportedFlashModes.contains(flashMode) {
            settings.flashMode = flashMode
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error _: Error?)
    {
        guard let data = photo.fileDataRepresentation(),
              let img = UIImage(data: data) else { return }
        onPhotoCapture?(img)
    }
}

// MARK: - Movie capture

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func recordVideo(duration: TimeInterval = 2.0) {
        if let device = videoDevice, device.hasTorch {
            try? device.lockForConfiguration()
            device.torchMode = (flashMode == .on) ? .on : .off
            device.unlockForConfiguration()
        }
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quick.mov")
        try? FileManager.default.removeItem(at: tmpURL)
        movieOutput.startRecording(to: tmpURL, recordingDelegate: self)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.movieOutput.stopRecording()
        }
    }

    func fileOutput(_: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from _: [AVCaptureConnection],
                    error _: Error?)
    {
        onVideoCapture?(outputFileURL)
    }
}
