//
//  Zoomable.swift
//  Photocap
//
//  Created by Pedro Braz on 11/05/25.
//

import SwiftUI

struct Zoomable: ViewModifier {
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        // combine with the last scale so it zooms cumulative
                        self.scale = self.lastScale * value
                    }
                    .onEnded { _ in
                        // save the last scale, clamp to minimum 1
                        self.lastScale = max(self.scale, 1.0)
                        self.scale = self.lastScale
                    }
            )
    }
}

extension View {
    func zoomable() -> some View {
        modifier(Zoomable())
    }
}
