//
//  ContentViewModel.swift
//  Photocap
//
//  Created by Pedro Braz on 11/05/25.
//

import AVFoundation
import Combine
import Photos
import SwiftUI
import UIKit

final class ContentViewModel: ObservableObject {
    // MARK: - Public/Internal Properties

    @Published var capturedImage: UIImage?
    @Published var currentFrame: UIImage?
    @Published var isRecording: Bool = false
    @Published var saveMessage: String = ""
    @Published var showSaveToast: Bool = false
    @Published var videoURL: URL?
    @Published var showSettingsAlert = false
    @Published var showCameraSettingsAlert = false

    var flashAccessibilityKey: String {
        switch cameraService.flashMode {
        case .auto: return "flash_auto"
        case .on: return "flash_on"
        case .off: return "flash_off"
        @unknown default: return "flash_auto"
        }
    }

    var flashIconName: String {
        switch cameraService.flashMode {
        case .auto: return "bolt.badge.a.fill"
        case .on: return "bolt.fill"
        case .off: return "bolt.slash.fill"
        @unknown default: return "bolt.badge.a.fill"
        }
    }

    var session: AVCaptureSession {
        cameraService.session
    }

    // MARK: - Private Properties

    private let cameraService: CameraService
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Init

    init(cameraService: CameraService = .init()) {
        self.cameraService = cameraService

        // Subscribe to flashMode changes so the UI updates
        cameraService.$flashMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &subscriptions)

        // Wire up capture callbacks
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
        saveImage(frame, success: "frame_saved", failure: "frame_save_failed")
    }

    func savePhoto() {
        guard let img = capturedImage else { return }
        saveImage(img, success: "photo_saved", failure: "photo_save_failed")
    }

    func setup() {
        cameraService.start()
    }

    func switchCamera() {
        cameraService.switchCamera()
    }

    func toggleFlash() {
        cameraService.toggleFlash()
    }

    func checkCameraAuthorization() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            cameraService.start()

        case .notDetermined:
            // first‐time: prompt
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.cameraService.start()
                    } else {
                        self.showCameraSettingsAlert = true
                    }
                }
            }

        case .denied, .restricted:
            // user has previously denied → show alert
            showCameraSettingsAlert = true

        @unknown default:
            showCameraSettingsAlert = true
        }
    }

    func saveImage(_ img: UIImage, success: String, failure: String) {
        // Since the is a lot of phone permissons to handle
        // (Camera, Photos, location etc)
        // one good improvement would be a PermissionManager to handle those scenarios
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized, .limited:
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest
                        .creationRequestForAsset(from: img)
                } completionHandler: { ok, _ in
                    // handleSaveResult will publish saveMessage/showSaveToast
                    // — dispatch it to the main queue
                    DispatchQueue.main.async {
                        self.handleSaveResult(
                            ok: ok,
                            success: success,
                            failure: failure
                        )
                    }
                }

            case .denied, .restricted:
                // user denied/restricted—show the Settings alert on main
                DispatchQueue.main.async {
                    self.showSettingsAlert = true
                }

            case .notDetermined:
                // should not happen here
                break

            @unknown default:
                break
            }
        }
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

    private func handleSaveResult(ok: Bool, success: String, failure: String) {
        let msgKey = ok ? success : failure
        saveMessage = NSLocalizedString(msgKey, comment: "")
        withAnimation {
            self.showSaveToast = true
        }
    }
}
