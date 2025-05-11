//
//  CameraServiceTests.swift
//  PhotocapTests
//
//  Created by Pedro Braz on 11/05/25.
//

@testable import Photocap
import XCTest

final class CameraServiceTests: XCTestCase {
    // I created some example unit tests, but there is space for improvement here
    // For example, I could create a CameraServiceProtocol to conform CameraService
    // That would allow me to create a more elaborated Mock for it and check
    // if the declared methods in the protocol are working as expected in the concrete class.

    func test_toggleFlash_whenCalled_shouldCycleThroughAllModes() {
        let cameraService = CameraService()
        cameraService.toggleFlash()
        XCTAssertEqual(cameraService.flashMode, .on)
        cameraService.toggleFlash()
        XCTAssertEqual(cameraService.flashMode, .off)
        cameraService.toggleFlash()
        XCTAssertEqual(cameraService.flashMode, .auto)
    }
}
