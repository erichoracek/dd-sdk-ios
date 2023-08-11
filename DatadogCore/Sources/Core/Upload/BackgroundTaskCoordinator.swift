/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import Foundation

internal protocol BackgroundTaskCoordinator {
    func registerBackgroundTask() -> UUID
    @discardableResult
    func endBackgroundTaskIfActive(_ uuid: UUID) -> Bool
}

#if canImport(UIKit)
import UIKit

/// The `BackgroundTaskCoordinator` class provides an abstraction for managing background tasks and includes methods for registering and ending background tasks.
/// It also serves as a useful abstraction for testing purposes.
internal class UIKitBackgroundTaskCoordinator: BackgroundTaskCoordinator {
    private var tasks: [UUID: UIBackgroundTaskIdentifier] = [:]

    internal func registerBackgroundTask() -> UUID {
        let uuid = UUID()
        tasks[uuid] = UIApplication.dd.managedShared?.beginBackgroundTask { [weak self] in
            self?.endBackgroundTaskIfActive(uuid)
        }
        return uuid
    }

    @discardableResult
    internal func endBackgroundTaskIfActive(_ uuid: UUID) -> Bool {
        if let backgroundTask = tasks[uuid], backgroundTask != .invalid {
            UIApplication.dd.managedShared?.endBackgroundTask(backgroundTask)
            tasks.removeValue(forKey: uuid)
            return true
        }
        return false
    }
}
#endif
