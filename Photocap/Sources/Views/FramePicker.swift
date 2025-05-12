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
    var onFrameChange: (UIImage) -> Void

    // MARK: Private Properties

    @State private var generator: AVAssetImageGenerator?
    @State private var frameImage: UIImage?

    // MARK: UI

    var body: some View {
        Group {
            if let img = frameImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .zoomable()
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .background(Color.black)
        // whenever `position` changes, ask the one generator for a new frame
        .onChange(of: frameTimePosition) { newPos in
            generateFrame(at: newPos)
        }
        // create & configure the generator once
        .onAppear {
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            gen.requestedTimeToleranceBefore = .zero
            gen.requestedTimeToleranceAfter = .zero
            generator = gen
            generateFrame(at: frameTimePosition)
        }
    }

    // MARK: Private Methods

    private func generateFrame(at seconds: Double) {
        guard let generator else { return }

        let time = CMTime(
            seconds: seconds,
            preferredTimescale: asset.duration.timescale
        )

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let cg = try generator.copyCGImage(at: time, actualTime: nil)
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
