//
//  ContentViewModelTests.swift
//  PhotocapTests
//
//  Created by Pedro Braz on 11/05/25.
//

@testable import Photocap
import XCTest

final class ContentViewModelTests: XCTestCase {
    // a simple mock to verify switchCamera is forwarded
    class MockCameraService: CameraService {
        var didSwitch = false
        override func switchCamera() {
            didSwitch = true
        }
    }

    func test_switchCamera_whenCalled_shouldInvokeService() {
        let mockCameraService = MockCameraService()
        let viewModel = ContentViewModel(cameraService: mockCameraService)
        viewModel.switchCamera()
        XCTAssertTrue(mockCameraService.didSwitch)
    }

    func test_toggleFlash_whenCalled_shouldUpdateIconName() {
        let mockCameraService = MockCameraService()
        let viewModel = ContentViewModel(cameraService: mockCameraService)
        XCTAssertEqual(viewModel.flashIconName, "bolt.badge.a.fill")
        viewModel.toggleFlash()
        XCTAssertEqual(viewModel.flashIconName, "bolt.fill")
        viewModel.toggleFlash()
        XCTAssertEqual(viewModel.flashIconName, "bolt.slash.fill")
    }

    func test_reset_whenCalled_shouldClearAllState() {
        let viewModel = ContentViewModel()
        viewModel.capturedImage = UIImage()
        viewModel.currentFrame = UIImage()
        viewModel.videoURL = URL(string: "file://test")
        viewModel.isRecording = true

        viewModel.reset()

        XCTAssertNil(viewModel.capturedImage)
        XCTAssertNil(viewModel.currentFrame)
        XCTAssertNil(viewModel.videoURL)
        XCTAssertFalse(viewModel.isRecording)
    }
}
