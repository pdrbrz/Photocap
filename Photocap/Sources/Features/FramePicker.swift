//
//  FramePicker.swift
//  Photocap
//
//  Created by Pedro Braz on 11/05/25.
//

import AVFoundation
import SwiftUI

struct FramePicker: View {
    let asset: AVAsset
    var onFrameChange: ((UIImage) -> Void)? // new

    @State private var position: Double = 0 // 0.0…1.0
    @State private var frameImage: UIImage?

    var body: some View {
        VStack {
            if let img = frameImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
                    .frame(maxHeight: .infinity)
            }

            Slider(value: $position)
                .padding(.horizontal)
                .onChange(of: position) { newPos in
                    let seconds = newPos * asset.duration.seconds
                    generatePreciseFrame(at: seconds)
                }
                .onAppear {
                    position = 0
                    generatePreciseFrame(at: 0)
                }
        }
        .background(Color.black)
    }

    private func generatePreciseFrame(at seconds: Double) {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let time = CMTime(seconds: seconds,
                          preferredTimescale: asset.duration.timescale)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let cg = try generator.copyCGImage(at: time, actualTime: nil)
                let ui = UIImage(cgImage: cg)
                DispatchQueue.main.async {
                    self.frameImage = ui
                    self.onFrameChange?(ui) // notify parent
                }
            } catch {
                print("Frame generation error:", error)
            }
        }
    }
}
