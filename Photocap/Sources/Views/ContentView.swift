//
//  ContentView.swift
//  Photocap
//
//  Created by Pedro Braz on 11/05/25.

import AVKit
import Combine
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var pageIndex = 0
    @State private var position: Double = Constants.maxVideoDuration / 2
    // The debounced position, passed into FramePicker
    // I added this to avoid a crash/"leak"
    // Before this change the user could slide the frame selector tool
    // very fast, creating dozens of frames at the same time
    // and crashing the app due memory shortage.
    // With this change there is a small wait time after the user
    // stops moving the slider to start generating the frame.
    @State private var debouncedPosition: Double = Constants.maxVideoDuration / 2
    @State private var positionSubject = PassthroughSubject<Double, Never>()
    @State private var cancellables = Set<AnyCancellable>()

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString)
        else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            // I would like to separate this UI components into other files
            // but I'll keep them here for the sake of simplicity,
            // and to don't take much longer than the requested time for the assessment

            if let img = viewModel.capturedImage,
               let vidURL = viewModel.videoURL
            {
                TabView(selection: $pageIndex) {
                    // MARK: Photo Page

                    VStack {
                        Spacer()

                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity,
                                   maxHeight: .infinity)
                            .zoomable()

                        Text(LocalizedStringKey("swipe_instruction"))
                            .foregroundColor(.white)
                            .padding(.bottom, Constants.Padding.small)

                        Button(LocalizedStringKey("save_photo"),
                               action: viewModel.savePhoto)
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .padding(.bottom, Constants.Padding.extraLarge)
                    }
                    .tag(0)
                    .ignoresSafeArea(edges: .top)
                    .clipShape(.rect(cornerRadius: Constants.CornerRadius.small, style: .circular))

                    // MARK: Video Page

                    VStack(spacing: 0) {
                        FramePicker(
                            asset: AVAsset(url: vidURL),
                            frameTimePosition: debouncedPosition
                        ) { frame in
                            viewModel.currentFrame = frame
                        }
                        .ignoresSafeArea(edges: .top)

                        Slider(value: $position,
                               in: 0 ... Constants.maxVideoDuration,
                               step: 1 / 30)
                            .padding(.horizontal, Constants.Padding.medium)
                            .padding(.top, Constants.Padding.small)
                            .padding(.bottom, Constants.Padding.medium)
                            // send raw slider changes into the subject
                            .onChange(of: position) { newValue in
                                positionSubject.send(newValue)
                            }

                        Button(LocalizedStringKey("save_frame"),
                               action: viewModel.saveFrame)
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .padding(.bottom, Constants.Padding.xExtraLarge)
                    }
                    .tag(1)
                }
                .clipShape(.rect(cornerRadius: Constants.CornerRadius.small, style: .circular))
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // MARK: Back Button

                Button {
                    viewModel.reset()
                    pageIndex = 0
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: Constants.Font.control,
                                      weight: .semibold))
                        .foregroundColor(.white)
                        .padding(Constants.Padding.xxxSmall)
                        .background(Color.black.opacity(Constants.Opacity.backButton))
                        .clipShape(Circle())
                        .accessibilityLabel(
                            LocalizedStringKey("back_button_accessibility")
                        )
                }
                .padding()
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )

            } else {
                // MARK: Live Camera Flow

                CameraPreview(session: viewModel.session)

                VStack {
                    Spacer()

                    if viewModel.capturedImage == nil {
                        Text(LocalizedStringKey("picture_instruction"))
                            .foregroundColor(.white)
                            .padding(.bottom, Constants.Padding.small)

                        Button(action: viewModel.capturePhoto) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: Constants.Font.capture))
                                .foregroundColor(.white)
                                .padding(Constants.Padding.large)
                                .background(Color.red)
                                .clipShape(Circle())
                        }

                    } else if viewModel.isRecording {
                        Text(LocalizedStringKey("recording"))
                            .foregroundColor(.white)
                            .padding(.bottom, Constants.Padding.small)

                    } else {
                        Text(LocalizedStringKey("record_instruction"))
                            .foregroundColor(.white)
                            .padding(.bottom, Constants.Padding.small)

                        Button(action: viewModel.recordVideo) {
                            Image(systemName: "record.circle.fill")
                                .font(.system(size: Constants.Font.capture))
                                .foregroundColor(.white)
                                .padding(Constants.Padding.large)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                    }

                    Spacer().frame(height: Constants.Spacer.bottom)
                }
                .padding(.horizontal, Constants.Padding.medium)

                // MARK: Top Controls

                VStack {
                    HStack {
                        Button(action: viewModel.toggleFlash) {
                            Image(systemName: viewModel.flashIconName)
                                .font(.system(size: Constants.Font.control))
                                .foregroundColor(.white)
                                .padding(Constants.Padding.small)
                                .background(Color.black.opacity(Constants.Opacity.topControl))
                                .clipShape(Circle())
                                .accessibilityLabel(
                                    viewModel.flashAccessibilityKey
                                )
                        }
                        Spacer()
                        Button(action: viewModel.switchCamera) {
                            Image(systemName: "camera.rotate.fill")
                                .font(.system(size: Constants.Font.control))
                                .foregroundColor(.white)
                                .padding(Constants.Padding.small)
                                .background(Color.black.opacity(Constants.Opacity.topControl))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, Constants.Padding.medium)
                    .padding(.top, Constants.Padding.large)
                    Spacer()
                }
            }

            // MARK: Toast Feedback

            if viewModel.showSaveToast {
                Text(viewModel.saveMessage)
                    .foregroundColor(.white)
                    .padding(.horizontal, Constants.Padding.medium)
                    .padding(.vertical, Constants.Padding.small)
                    .background(.ultraThinMaterial)
                    .cornerRadius(Constants.CornerRadius.toast)
                    .transition(.opacity)
                    .zIndex(1)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.Animation.toastDisplay) {
                            withAnimation(.easeOut(duration: Constants.Animation.toastFade)) {
                                viewModel.showSaveToast = false
                            }
                        }
                    }
                    .padding(.top, Constants.Padding.toastTop)
            }
        }
        .onAppear {
            // Check camera permission and start session
            viewModel.checkCameraAuthorization()
            positionSubject
                .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
                .sink { newValue in
                    debouncedPosition = newValue
                }
                .store(in: &cancellables)
        }
        // Camera permission alert
        .alert("Camera Access Needed",
               isPresented: $viewModel.showCameraSettingsAlert)
        {
            Button("Go to Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString)
                else { return }
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow camera access in Settings to take photos and videos.")
        }
        // Photos permission alert
        .alert("Photos Permission Needed",
               isPresented: $viewModel.showSettingsAlert)
        {
            Button("Go to Settings") {
                openSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow Photos access so you can save your photos and videos.")
        }
        .animation(.easeInOut(duration: Constants.Animation.quick),
                   value: viewModel.showSaveToast)
    }
}
