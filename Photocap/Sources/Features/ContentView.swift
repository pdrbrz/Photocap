//
//  ContentView.swift
//  Photocap
//
//  Created by Pedro Braz on 11/05/25.
//

import AVFoundation
import AVKit
import Photos
import SwiftUI

struct ContentView: View {
    @StateObject private var camera = CameraService()
    @State private var capturedImage: UIImage?
    @State private var videoURL: URL?
    @State private var currentFrame: UIImage?
    @State private var isRecording = false

    @State private var saveMessage = ""
    @State private var showSaveToast = false

    private var flashIconName: String {
        switch camera.flashMode {
        case .auto: return "bolt.badge.a.fill"
        case .on: return "bolt.fill"
        case .off: return "bolt.slash.fill"
        @unknown default: return "bolt.badge.a.fill"
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let img = capturedImage, let vidURL = videoURL {
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        VStack(spacing: 0) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width,
                                       height: geo.size.height / 2)
                                .cornerRadius(8)

                            FramePicker(asset: AVAsset(url: vidURL)) { frame in
                                currentFrame = frame
                            }
                            .frame(width: geo.size.width,
                                   height: geo.size.height / 2)
                            .cornerRadius(8)
                        }
                    }

                    HStack {
                        Button("Save Photo") {
                            savePhoto()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)

                        Spacer()

                        Button("Save Frame") {
                            saveFrame()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                    .padding()
                }
            } else {
                CameraPreview(session: camera.session)

                VStack {
                    Spacer()

                    if capturedImage == nil {
                        Button {
                            camera.capturePhoto()
                        } label: {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .padding(24)
                                .background(Color.red)
                                .clipShape(Circle())
                        }

                    } else {
                        if isRecording {
                            Text("Recording…")
                                .foregroundColor(.white)
                                .padding(.bottom, 8)
                        } else {
                            Button {
                                isRecording = true
                                camera.recordVideo(duration: 2)
                            } label: {
                                Image(systemName: "record.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                    .padding(24)
                                    .background(Color.red)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
                .padding(.horizontal)
                VStack {
                    HStack {
                        // Toggle flash
                        Button(action: camera.toggleFlash) {
                            Image(systemName: flashIconName)
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        Spacer()
                        // Flip camera
                        Button(action: camera.switchCamera) {
                            Image(systemName: "camera.rotate.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    Spacer()
                }
            }

            if showSaveToast {
                Text(saveMessage)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    .transition(.opacity)
                    .zIndex(1)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                showSaveToast = false
                            }
                        }
                    }
                    .padding(.top, 50)
            }
        }
        .onAppear {
            camera.start()
            camera.onPhotoCapture = { img in
                capturedImage = img
            }
            camera.onVideoCapture = { url in
                videoURL = url
                isRecording = false
                camera.stop()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSaveToast)
    }

    private func savePhoto() {
        guard let img = capturedImage else { return }
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: img)
                }) { success, _ in
                    DispatchQueue.main.async {
                        saveMessage = success ? "Photo saved!" : "Photo save failed"
                        withAnimation(.easeIn(duration: 0.25)) {
                            showSaveToast = true
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    saveMessage = "Photo library access denied"
                    withAnimation(.easeIn(duration: 0.25)) {
                        showSaveToast = true
                    }
                }
            }
        }
    }

    private func saveFrame() {
        guard let frame = currentFrame else { return }
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: frame)
                }) { success, _ in
                    DispatchQueue.main.async {
                        saveMessage = success ? "Frame saved!" : "Frame save failed"
                        withAnimation(.easeIn(duration: 0.25)) {
                            showSaveToast = true
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    saveMessage = "Photo library access denied"
                    withAnimation(.easeIn(duration: 0.25)) {
                        showSaveToast = true
                    }
                }
            }
        }
    }
}
