/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

extension JSONEncoder {
    static func `default`() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ISO8601DateFormatter.encodingStrategy
        if #available(iOS 13.0, OSX 10.15, *) {
            encoder.outputFormatting = [.withoutEscapingSlashes]
        }
        return encoder
    }
}
