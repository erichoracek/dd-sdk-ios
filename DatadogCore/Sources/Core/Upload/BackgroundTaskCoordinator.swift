/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import Foundation

/// The `BackgroundTaskCoordinator` protocol provides an abstraction for managing background tasks and includes methods for registering and ending background tasks.
/// It serves as a useful abstraction for testing purposes as well as allows decoupling from UIKit in order to maintain Catalyst compliation.
internal protocol BackgroundTaskCoordinator {
    func registerBackgroundTask() -> BackgroundTaskIdentifier?
    func endBackgroundTaskIfActive(_ backgroundTaskIdentifier: BackgroundTaskIdentifier)
}

internal typealias BackgroundTaskIdentifier = Int

#if canImport(UIKit)
import UIKit

internal class UIKitBackgroundTaskCoordinator: BackgroundTaskCoordinator {
    internal func registerBackgroundTask() -> BackgroundTaskIdentifier? {
        return UIApplication.dd.managedShared?.beginBackgroundTask().rawValue
    }

    func endBackgroundTaskIfActive(_ backgroundTaskIdentifier: BackgroundTaskIdentifier) {
        UIApplication.dd.managedShared?.endBackgroundTask(.init(rawValue: backgroundTaskIdentifier))
    }
}
#endif
