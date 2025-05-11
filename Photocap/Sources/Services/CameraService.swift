//
//  CameraService.swift
//  Photocap
//
//  Created by Pedro Braz on 11/05/25.
//
import AVFoundation
import UIKit

class CameraService: NSObject, ObservableObject {
    // MARK: - Public/Internal Properties

    @Published private(set) var currentPosition: AVCaptureDevice.Position = .back
    @Published private(set) var flashMode: AVCaptureDevice.FlashMode = .auto
    private(set) var session = AVCaptureSession()

    // MARK: - Callbacks

    /// Fires when a photo is captured
    var onPhotoCapture: ((UIImage) -> Void)?
    /// Fires when a video file is recorded
    var onVideoCapture: ((URL) -> Void)?

    // MARK: - Private Properties

    private let movieOutput = AVCaptureMovieFileOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDevice: AVCaptureDevice?

    // MARK: - Init

    override init() {
        super.init()
        configureSession()
    }

    // MARK: - Public/Internal Methods

    /// Starts the capture session on a background queue.
    func start() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    /// Stops the capture session.
    func stop() {
        guard session.isRunning else { return }
        session.stopRunning()
    }

    /// Captures a single photo, applying `flashMode` if supported.
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        if photoOutput.supportedFlashModes.contains(flashMode) {
            settings.flashMode = flashMode
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    /// Records a short video (default 2 s), toggling the torch if needed.
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

    /// Toggles between front and back camera.
    func switchCamera() {
        guard
            let currentInput = session.inputs
            .compactMap({ $0 as? AVCaptureDeviceInput })
            .first(where: { $0.device.hasMediaType(.video) }),
            let newDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: currentInput.device.position == .back ? .front : .back
            ),
            let newInput = try? AVCaptureDeviceInput(device: newDevice)
        else { return }

        session.beginConfiguration()
        session.removeInput(currentInput)
        if session.canAddInput(newInput) {
            session.addInput(newInput)
            currentPosition = newDevice.position
            videoDevice = newDevice
        }
        session.commitConfiguration()
    }

    /// Cycles flash: `.auto` → `.on` → `.off` → `.auto`
    func toggleFlash() {
        switch flashMode {
        case .auto: flashMode = .on
        case .on: flashMode = .off
        case .off: flashMode = .auto
        @unknown default: flashMode = .auto
        }
    }

    /// Provides a preview layer for embedding in SwiftUI.
    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    // MARK: - Private Methods

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        // video input
        if let cam = AVCaptureDevice
            .default(.builtInWideAngleCamera, for: .video, position: .back)
        {
            videoDevice = cam
            if let videoIn = try? AVCaptureDeviceInput(device: cam),
               session.canAddInput(videoIn)
            {
                session.addInput(videoIn)
            }
            // I choose to lock the video into 30fps and limit to 2 seconds for the sake of simplicity
            // That way the user has 60 frames to pick from instead of, for example, 600 frames from 60fps for 10 seconds
            if let _ = cam.activeFormat.videoSupportedFrameRateRanges
                .first(where: { $0.maxFrameRate >= 60 })
            {
                try? cam.lockForConfiguration()
                cam.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
                cam.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
                cam.unlockForConfiguration()
            }
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }

        session.commitConfiguration()
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error _: Error?)
    {
        guard
            let data = photo.fileDataRepresentation(),
            let img = UIImage(data: data)
        else { return }
        onPhotoCapture?(img)
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from _: [AVCaptureConnection],
                    error _: Error?)
    {
        onVideoCapture?(outputFileURL)
    }
}
