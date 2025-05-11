//  FramePicker.swift
//  Photocap
//
//  Created by Pedro Braz on 11/05/25.
//

import AVFoundation
import SwiftUI

struct FramePicker: View {
    // MARK: Properties

    let asset: AVAsset
    let frameTimePosition: Double
    var onFrameChange: (UIImage) -> Void //

    @State private var frameImage: UIImage?

    var body: some View {
        Group {
            if let img = frameImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .background(Color.black)
        .zoomable()
        .onChange(of: frameTimePosition) { newPos in
            generatePreciseFrame(at: newPos)
        }
        .onAppear {
            generatePreciseFrame(at: frameTimePosition)
        }
    }

    // MARK: Private Methods

    private func generatePreciseFrame(at seconds: Double) {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let time = CMTime(
            seconds: seconds,
            preferredTimescale: asset.duration.timescale
        )
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let cg = try generator.copyCGImage(
                    at: time,
                    actualTime: nil
                )
                let ui = UIImage(cgImage: cg)
                DispatchQueue.main.async {
                    frameImage = ui
                    onFrameChange(ui)
                }
            } catch {
                print("Frame generation error:", error)
            }
        }
    }
}
