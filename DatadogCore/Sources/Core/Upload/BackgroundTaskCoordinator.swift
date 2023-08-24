/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import Foundation

/// The `BackgroundTaskCoordinator` protocol provides an abstraction for managing background tasks and includes methods for registering and ending background tasks.
/// It serves as a useful abstraction for testing purposes as well as allows decoupling from UIKit in order to maintain Catalyst compliation. To abstract from UIKit, it leverages
/// the fact that UIBackgroundTaskIdentifier raw value is based on Int.
internal protocol BackgroundTaskCoordinator {
    func registerBackgroundTask() -> Int
    func endBackgroundTaskIfActive(_ backgroundTaskIdentifier: Int)
}

#if canImport(UIKit)
import UIKit

internal class UIKitBackgroundTaskCoordinator: BackgroundTaskCoordinator {
    private var currentBackgroundTask: UIBackgroundTaskIdentifier = .invalid

    internal func registerBackgroundTask() -> Int {
        guard let app = UIApplication.dd.managedShared else {
            return UIBackgroundTaskIdentifier.invalid.rawValue
        }
        currentBackgroundTask = app.beginBackgroundTask(expirationHandler: { [currentBackgroundTask] in
            UIApplication.dd.managedShared?.endBackgroundTask(currentBackgroundTask)
        })
        return currentBackgroundTask.rawValue
    }

    func endBackgroundTaskIfActive(_ backgroundTaskIdentifier: Int) {
        UIApplication.dd.managedShared?.endBackgroundTask(.init(rawValue: backgroundTaskIdentifier))
        currentBackgroundTask = .invalid
    }
}
#endif
