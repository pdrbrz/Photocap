//
//  Constants.swift
//  Photocap
//
//  Created by Pedro Braz on 11/05/25.
//

import Foundation

enum Constants {
    static let maxVideoDuration: Double = 2.0

    enum Padding {
        static let xxxSmall: CGFloat = 12
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 28
        static let huge: CGFloat = 80
        static let toastTop: CGFloat = 50
    }

    enum Font {
        static let control: CGFloat = 20
        static let capture: CGFloat = 28
    }

    enum Opacity {
        static let backButton: Double = 0.6
        static let topControl: Double = 0.5
    }

    enum Spacer {
        static let bottom: CGFloat = 40
    }

    enum CornerRadius {
        static let toast: CGFloat = 10
    }

    enum Animation {
        static let quick: Double = 0.25
        static let toastDisplay: Double = 1.0
        static let toastFade: Double = 0.5
    }
}
