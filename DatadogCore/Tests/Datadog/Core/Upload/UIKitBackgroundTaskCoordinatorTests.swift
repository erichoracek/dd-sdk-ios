/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import XCTest
@testable import DatadogCore

class UIKitBackgroundTaskCoordinatorTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var coordinator: UIKitBackgroundTaskCoordinator!

    override func setUp() {
        super.setUp()
        coordinator = UIKitBackgroundTaskCoordinator()
    }

    override func tearDown() {
        coordinator = nil
        super.tearDown()
    }

    func testRegisterBackgroundTask() {
        let uuid = coordinator.registerBackgroundTask()
        XCTAssertNotNil(coordinator.tasks[uuid])
    }

    func testEndBackgroundTaskIfActive() {
        let uuid = coordinator.registerBackgroundTask()
        XCTAssertTrue(coordinator.endBackgroundTaskIfActive(uuid))
        XCTAssertNil(coordinator.tasks[uuid])
    }

    func testEndBackgroundTaskIfActive_InvalidUUID() {
        let uuid = UUID()
        XCTAssertFalse(coordinator.endBackgroundTaskIfActive(uuid))
        XCTAssertNil(coordinator.tasks[uuid])
    }
}
