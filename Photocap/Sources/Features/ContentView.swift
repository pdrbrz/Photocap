//
//  ContentView.swift
//  Photocap
//
//  Created by Pedro Braz on 11/05/25.
//
import AVKit
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let img = viewModel.capturedImage,
               let url = viewModel.videoURL
            {
                // Final comparison
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        VStack(spacing: 0) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width,
                                       height: geo.size.height / 2)
                                .cornerRadius(8)

                            FramePicker(asset: AVAsset(url: url)) {
                                viewModel.currentFrame = $0
                            }
                            .frame(width: geo.size.width,
                                   height: geo.size.height / 2)
                            .cornerRadius(8)
                        }
                    }

                    HStack {
                        Button("Save Photo", action: viewModel.savePhoto)
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        Spacer()
                        Button("Save Frame", action: viewModel.saveFrame)
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                    }
                    .padding()
                }
                .overlay(alignment: .topLeading) {
                    Button {
                        viewModel.reset()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding()
                }

            } else {
                // Capture flow
                CameraPreview(session: viewModel.session)

                VStack {
                    Spacer()
                    if viewModel.capturedImage == nil {
                        Button(action: viewModel.capturePhoto) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .padding(24)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                    } else {
                        if viewModel.isRecording {
                            Text("Recording…")
                                .foregroundColor(.white)
                                .padding(.bottom, 8)
                        } else {
                            Button(action: viewModel.recordVideo) {
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
                        Button(action: viewModel.toggleFlash) {
                            Image(systemName: viewModel.flashIconName)
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        Spacer()
                        Button(action: viewModel.switchCamera) {
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

            if viewModel.showSaveToast {
                Text(viewModel.saveMessage)
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
                                viewModel.showSaveToast = false
                            }
                        }
                    }
                    .padding(.top, 50)
            }
        }
        .onAppear(perform: viewModel.setup)
        .animation(.easeInOut(duration: 0.25),
                   value: viewModel.showSaveToast)
    }
}
