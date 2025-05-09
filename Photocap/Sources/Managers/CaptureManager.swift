//
//  CaptureManager.swift
//  Photocap
//
//  Created by Pedro Braz on 09/05/25.
//

import AVFoundation
import Combine
import UIKit

final class CaptureManager: NSObject, ObservableObject {
    // MARK: Public/Internal Properties

    @Published var capturedPhoto: UIImage?
    @Published var recordedVideoURL: URL?
    @Published var selectedFrame: UIImage?
    @Published var errorMessage: String?
    @Published var saveMessage: String?

    // MARK: Private Properties

    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private let queue = DispatchQueue(label: "capture.queue")
    private var tempURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("capture.mov")
    }

    // MARK: Initialization

    override init() {
        super.init()
        configureSession()
    }

    // MARK: Public/Internal Methods

    func startSession() {
        guard !session.isRunning else { return }
        queue.async {
            self.session.startRunning()
            DispatchQueue.main.async {
                if !self.session.isRunning {
                    self.errorMessage = NSLocalizedString("failed_to_start_session_error", comment: "")
                }
            }
        }
    }

    func stopSession() {
        guard session.isRunning else { return }
        queue.async {
            self.session.stopRunning()
            DispatchQueue.main.async {
                if self.session.isRunning {
                    self.errorMessage = NSLocalizedString("failed_to_stop_session_error", comment: "")
                }
            }
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func startRecording() {
        do {
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
        } catch {
            errorMessage = String(format: NSLocalizedString("failed_to_clear_temp_error", comment: ""), error.localizedDescription)
            return
        }
        movieOutput.startRecording(to: tempURL, recordingDelegate: self)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.movieOutput.isRecording {
                self.movieOutput.stopRecording()
            }
        }
    }

    func stopRecording() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
    }

    func savePhotoToLibrary() {
        guard let image = capturedPhoto else {
            saveMessage = NSLocalizedString("no_photo_to_save_error", comment: "")
            return
        }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveHandler(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    func saveSelectedFrameToLibrary() {
        guard let image = selectedFrame else {
            saveMessage = NSLocalizedString("no_frame_to_save_error", comment: "")
            return
        }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveHandler(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    // MARK: Private Methods

    private func configureSession() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            errorMessage = NSLocalizedString("no_front_camera_error", comment: "")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            session.addInput(input)
        } catch {
            errorMessage = String(format: NSLocalizedString("failed_to_add_camera_input_error", comment: ""), error.localizedDescription)
            return
        }
        do {
            // Here I opted for a 3 seconds and 30 fps recording (90 frames).
            // Since the user is going to pick a single frame, this will
            // make it easier than choosing from a 10sec 60fps video (600 frames).
            try device.lockForConfiguration()
            let fps = 30.0
            let duration = CMTimeMake(value: 1, timescale: Int32(fps))
            device.activeVideoMinFrameDuration = duration
            device.activeVideoMaxFrameDuration = duration
            device.unlockForConfiguration()
        } catch {
            errorMessage = NSLocalizedString("failed_to_set_frame_rate_error", comment: "")
        }
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        } else {
            errorMessage = NSLocalizedString("cannot_add_photo_output_error", comment: "")
        }
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        } else {
            errorMessage = NSLocalizedString("cannot_add_movie_output_error", comment: "")
        }
    }

    @objc private func saveHandler(_: UIImage, didFinishSavingWithError error: Error?, contextInfo _: UnsafeRawPointer) {
        DispatchQueue.main.async {
            if let error = error {
                self.errorMessage = String(format: NSLocalizedString("save_error", comment: ""), error.localizedDescription)
            } else {
                self.saveMessage = NSLocalizedString("image_saved_message", comment: "")
            }
        }
    }
}

// MARK: - CaptureManager Delegates

extension CaptureManager: AVCapturePhotoCaptureDelegate {
    // MARK: AVCapturePhotoCaptureDelegate Internal

    func photoOutput(_: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            errorMessage = String(format: NSLocalizedString("photo_capture_error", comment: ""), error.localizedDescription)
            return
        }
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            errorMessage = NSLocalizedString("unable_to_process_photo_data_error", comment: "")
            return
        }
        capturedPhoto = image
    }
}

extension CaptureManager: AVCaptureFileOutputRecordingDelegate {
    // MARK: AVCaptureFileOutputRecordingDelegate Internal

    func fileOutput(_: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from _: [AVCaptureConnection], error: Error?) {
        if let error = error {
            errorMessage = String(format: NSLocalizedString("video_recording_error", comment: ""), error.localizedDescription)
            return
        }
        recordedVideoURL = outputFileURL
    }
}
