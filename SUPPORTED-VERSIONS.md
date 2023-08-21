## Platforms

| Platform   | Supported |  Version  |
|------------|:---------:|-------:|
| **iOS**    |     ✅    |  `11+` |
| **tvOS**   |     ✅    |  `11+` |
| **iPadOS** |     ✅    |  `11+` |
| **watchOS**|     ❌    |  `n/a` |
| **macOS**  |     ❌    |  `n/a` |
| **Linux**  |     ❌    |  `n/a` |

## Xcode

SDK is built using the most recent version of Xcode, but we make sure that it's backward compatible with the [lowest supported Xcode version for AppStore submission](https://developer.apple.com/news/?id=jd9wcyov).

## Dependency Managers

We currently support integration of the SDK using following dependency managers.
- [Swift Package Manager](https://docs.datadoghq.com/logs/log_collection/ios/?tab=swiftpackagemanagerspm)
- [Cocoapods](https://docs.datadoghq.com/logs/log_collection/ios/?tab=cocoapods)
- [Carthage](https://docs.datadoghq.com/logs/log_collection/ios/?tab=carthage)

## Languages

| Language        |   Version    |
|-----------------|:------------:|
| **Swift**       |     `5.*`    |
| **Objective-C** |     `2.0`    |

## UI Framework Instrumentation

| Framework       |   Automatic  | Manual |
|-----------------|:------------:|:------:|
| **UIKit**       |       ✅     |   ✅    |
| **SwiftUI**     |       ❌     |   ✅    |

## Networking Compatibility
| Framework       |   Automatic  | Manual |
|-----------------|:------------:|:------:|
| **URLSession**  |       ✅     |   ✅    |
|[**Alamofire 5+**](https://github.com/DataDog/dd-sdk-ios/tree/develop/Sources/DatadogExtensions/Alamofire) |       ❌     |   ✅    |
|  **SwiftNIO**   |       ❌     |   ❌    |

*Note: Third party networking libraries can be instrumented by implementing custom `DDURLSessionDelegate`.*

## Catalyst
We support Catalyst in build mode only, which means that macOS target will build, but functionalities for the SDK won't work for this target.

## Dependencies
The Datadog SDK depends on the following third-party library:
- [PLCrashReporter](https://github.com/microsoft/plcrashreporter) 1.11.1