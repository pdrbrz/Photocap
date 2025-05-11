//
//  CameraPreview.swift
//  Photocap
//
//  Created by Pedro Braz on 11/05/25.
//

import AVFoundation
import SwiftUI

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context _: Context) -> UIView {
        let view = UIView(frame: .zero)
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = UIScreen.main.bounds
        view.layer.addSublayer(preview)
        return view
    }

    func updateUIView(_: UIView, context _: Context) {
        // nothing to update
    }
}
