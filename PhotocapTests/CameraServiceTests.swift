//
//  CameraServiceTests.swift
//  PhotocapTests
//
//  Created by Pedro Braz on 11/05/25.
//

@testable import Photocap
import XCTest

final class CameraServiceTests: XCTestCase {
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
