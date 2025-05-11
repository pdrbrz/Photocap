//
//  ContentViewModel.swift
//  Photocap
//
//  Created by Pedro Braz on 11/05/25.
//

import AVFoundation
import Photos
import UIKit

final class ContentViewModel: ObservableObject {
    // MARK: - Public/Internal Properties

    @Published var capturedImage: UIImage?
    @Published var currentFrame: UIImage?
    @Published var isRecording = false
    @Published var saveMessage = ""
    @Published var showSaveToast = false
    @Published var videoURL: URL?

    var flashIconName: String {
        switch cameraService.flashMode {
        case .auto: return "bolt.badge.a.fill"
        case .on: return "bolt.fill"
        case .off: return "bolt.slash.fill"
        @unknown default: return "bolt.badge.a.fill"
        }
    }

    var session: AVCaptureSession { cameraService.session }

    // MARK: - Private Properties

    private let cameraService: CameraService

    // MARK: - Init

    init(cameraService: CameraService = .init()) {
        self.cameraService = cameraService

        // wire callbacks
        cameraService.onPhotoCapture = { [weak self] img in
            self?.handlePhotoCapture(img)
        }
        cameraService.onVideoCapture = { [weak self] url in
            self?.handleVideoCapture(url)
        }
    }

    // MARK: - Public/Internal Methods

    func capturePhoto() {
        cameraService.capturePhoto()
    }

    func recordVideo() {
        isRecording = true
        cameraService.recordVideo()
    }

    func reset() {
        cameraService.stop()
        capturedImage = nil
        currentFrame = nil
        videoURL = nil
        isRecording = false
        cameraService.start()
    }

    func saveFrame() {
        guard let frame = currentFrame else { return }
        saveImage(frame, success: "Frame saved!", failure: "Frame save failed")
    }

    func savePhoto() {
        guard let img = capturedImage else { return }
        saveImage(img, success: "Photo saved!", failure: "Photo save failed")
    }

    func setup() {
        cameraService.start()
    }

    func switchCamera() {
        cameraService.switchCamera()
    }

    func toggleFlash() {
        cameraService.toggleFlash()
        objectWillChange.send()
    }

    // MARK: - Private Methods

    private func handlePhotoCapture(_ img: UIImage) {
        DispatchQueue.main.async {
            self.capturedImage = img
        }
    }

    private func handleVideoCapture(_ url: URL) {
        DispatchQueue.main.async {
            self.videoURL = url
            self.isRecording = false
            self.cameraService.stop()
        }
    }

    private func saveImage(_ img: UIImage, success: String, failure: String) {
        PHPhotoLibrary.requestAuthorization { status in
            var msg = ""
            if status == .authorized || status == .limited {
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: img)
                } completionHandler: { ok, _ in
                    msg = ok ? success : failure
                    DispatchQueue.main.async {
                        self.saveMessage = msg
                        self.showSaveToast = true
                    }
                }
            } else {
                msg = "Library access denied"
                DispatchQueue.main.async {
                    self.saveMessage = msg
                    self.showSaveToast = true
                }
            }
        }
    }
}
