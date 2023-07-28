/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import XCTest
import TestUtilities
@testable import DatadogInternal

class NetworkInstrumentationFeatureTests: XCTestCase {
    // swiftlint:disable implicitly_unwrapped_optional
    private var core: SingleFeatureCoreMock<NetworkInstrumentationFeature>!
    private var handler: URLSessionHandlerMock!
    // swiftlint:enable implicitly_unwrapped_optional

    override func setUpWithError() throws {
        try super.setUpWithError()

        core = SingleFeatureCoreMock()
        handler = URLSessionHandlerMock()

        try core.register(urlSessionHandler: handler)
    }

    override func tearDown() {
        core = nil
        handler = nil
        super.tearDown()
    }

    // MARK: - Interception Flow

    func testGivenURLSessionWithDatadogDelegate_whenUsingTaskWithURL_itNotifiesInterceptor() {
        let notifyInterceptionStart = expectation(description: "Notify interception did start")
        let notifyInterceptionComplete = expectation(description: "Notify intercepion did complete")
        let server = ServerMock(delivery: .success(response: .mockResponseWith(statusCode: 200), data: .mock(ofSize: 10)))

        handler.onInterceptionStart = { _ in notifyInterceptionStart.fulfill() }
        handler.onInterceptionComplete = { _ in notifyInterceptionComplete.fulfill() }

        // Given
        let delegate = DatadogURLSessionDelegate(in: core)
        let session = server.getInterceptedURLSession(delegate: delegate)

        // When
        let task = session.dataTask(with: URL.mockAny())
        task.resume()

        // Then
        wait(
            for: [
                notifyInterceptionStart,
                notifyInterceptionComplete
            ],
            timeout: 0.5,
            enforceOrder: true
        )
        _ = server.waitAndReturnRequests(count: 1)
    }

    func testGivenURLSessionWithDatadogDelegate_whenUsingTaskWithURLRequest_itNotifiesInterceptor() {
        let notifyRequestMutation = expectation(description: "Notify request mutation")
        let notifyInterceptionStart = expectation(description: "Notify interception did start")
        let notifyInterceptionComplete = expectation(description: "Notify intercepion did complete")
        let server = ServerMock(delivery: .success(response: .mockResponseWith(statusCode: 200), data: .mock(ofSize: 10)))

        handler.onRequestMutation = { _, _ in notifyRequestMutation.fulfill() }
        handler.onInterceptionStart = { _ in notifyInterceptionStart.fulfill() }
        handler.onInterceptionComplete = { _ in notifyInterceptionComplete.fulfill() }

        // Given
        let url: URL = .mockAny()
        handler.firstPartyHosts = .init(
            hostsWithTracingHeaderTypes: [url.host!: [.datadog]]
        )
        let delegate = DatadogURLSessionDelegate(in: core)
        let session = server.getInterceptedURLSession(delegate: delegate)

        // When
        session
            .dataTask(with: URLRequest(url: url))
            .resume()

        // Then
        wait(
            for: [
                notifyRequestMutation,
                notifyInterceptionStart,
                notifyInterceptionComplete
            ],
            timeout: 0.5,
            enforceOrder: true
        )
        _ = server.waitAndReturnRequests(count: 1)
    }

    // MARK: - Interception Values

    func testGivenURLSessionWithDatadogDelegate_whenTaskCompletesWithFailure_itPassesAllValuesToTheInterceptor() throws {
        let notifyInterceptionStart = expectation(description: "Notify interception did start")
        let notifyInterceptionComplete = expectation(description: "Notify intercepion did complete")
        notifyInterceptionStart.expectedFulfillmentCount = 2
        notifyInterceptionComplete.expectedFulfillmentCount = 2

        let expectedError = NSError(domain: "network", code: 999, userInfo: [NSLocalizedDescriptionKey: "some error"])
        let server = ServerMock(delivery: .failure(error: expectedError))

        handler.onInterceptionStart = { _ in notifyInterceptionStart.fulfill() }
        handler.onInterceptionComplete = { _ in notifyInterceptionComplete.fulfill() }

        let dateBeforeAnyRequests = Date()

        // Given
        let delegate = DatadogURLSessionDelegate(in: core)
        let session = server.getInterceptedURLSession(delegate: delegate)

        // When
        let url1: URL = .mockRandom()
        session
            .dataTask(with: url1)
            .resume()

        let url2: URL = .mockRandom()
        session
            .dataTask(with: URLRequest(url: url2))
            .resume()

        // Then
        waitForExpectations(timeout: 1, handler: nil)
        _ = server.waitAndReturnRequests(count: 1)

        let dateAfterAllRequests = Date()

        XCTAssertEqual(handler.interceptions.count, 2, "Interceptor should record metrics for 2 tasks")

        try [url1, url2].forEach { url in
            let interception = try XCTUnwrap(handler.interception(for: url))
            let metrics = try XCTUnwrap(interception.metrics)
            XCTAssertGreaterThan(metrics.fetch.start, dateBeforeAnyRequests)
            XCTAssertLessThan(metrics.fetch.end, dateAfterAllRequests)
            XCTAssertNil(interception.data, "Data should not be recorded for \(url)")
            XCTAssertEqual((interception.completion?.error as? NSError)?.localizedDescription, "some error")
        }
    }

    func testGivenURLSessionWithDatadogDelegate_whenTaskCompletesWithSuccess_itPassesAllValuesToTheInterceptor() throws {
        let notifyInterceptionStart = expectation(description: "Notify interception did start")
        let notifyInterceptionComplete = expectation(description: "Notify intercepion did complete")
        notifyInterceptionStart.expectedFulfillmentCount = 2
        notifyInterceptionComplete.expectedFulfillmentCount = 2

        let randomData: Data = .mockRandom()
        let server = ServerMock(delivery: .success(response: .mockResponseWith(statusCode: 200), data: randomData))

        handler.onInterceptionStart = { _ in notifyInterceptionStart.fulfill() }
        handler.onInterceptionComplete = { _ in notifyInterceptionComplete.fulfill() }

        let dateBeforeAnyRequests = Date()

        // Given
        let delegate = DatadogURLSessionDelegate(in: core)
        let session = server.getInterceptedURLSession(delegate: delegate)

        // When
        let url1 = URL.mockRandom()
        session
            .dataTask(with: url1)
            .resume()

        let url2 = URL.mockRandom()
        session
            .dataTask(with: URLRequest(url: url2))
            .resume()

        // Then
        waitForExpectations(timeout: 0.5, handler: nil)
        _ = server.waitAndReturnRequests(count: 1)

        let dateAfterAllRequests = Date()

        XCTAssertEqual(handler.interceptions.count, 2, "Interceptor should record metrics for 2 tasks")

        try [url1, url2].forEach { url in
            let interception = try XCTUnwrap(handler.interception(for: url))
            let metrics = try XCTUnwrap(interception.metrics)
            XCTAssertGreaterThan(metrics.fetch.start, dateBeforeAnyRequests)
            XCTAssertLessThan(metrics.fetch.end, dateAfterAllRequests)
            XCTAssertEqual(interception.data, randomData)
            XCTAssertNotNil(interception.completion)
            XCTAssertNil(interception.completion?.error)
        }
    }

    // MARK: - Usage

    func testItCanBeInitializedBeforeInitializingDefaultSDKCore() throws {
        // Given
        let delegate1 = DatadogURLSessionDelegate()
        let delegate2 = DatadogURLSessionDelegate(additionalFirstPartyHosts: [])
        let delegate3 = DatadogURLSessionDelegate(additionalFirstPartyHostsWithHeaderTypes: [:])

        // When
        CoreRegistry.register(default: core)
        defer { CoreRegistry.unregisterDefault() }

        // Then
        XCTAssertNotNil(delegate1.interceptor)
        XCTAssertNotNil(delegate2.interceptor)
        XCTAssertNotNil(delegate3.interceptor)
    }

    func testItCanBeInitializedAfterInitializingDefaultSDKCore() throws {
        // Given
        CoreRegistry.register(default: core)
        defer { CoreRegistry.unregisterDefault() }

        // When
        let delegate1 = DatadogURLSessionDelegate()
        let delegate2 = DatadogURLSessionDelegate(additionalFirstPartyHosts: [])
        let delegate3 = DatadogURLSessionDelegate(additionalFirstPartyHostsWithHeaderTypes: [:])

        // Then
        XCTAssertNotNil(delegate1.interceptor)
        XCTAssertNotNil(delegate2.interceptor)
        XCTAssertNotNil(delegate3.interceptor)
    }

    func testItOnlyKeepsInstrumentationWhileSDKCoreIsAvailableInMemory() throws {
        // Given
        let delegate = DatadogURLSessionDelegate(in: core)
        // Then
        XCTAssertNotNil(delegate.interceptor)

        // When (deinitialize core)
        core = nil
        // Then
        XCTAssertNil(delegate.interceptor)
    }

    // MARK: - URLRequest Interception

    func testGivenOpenTracing_whenInterceptingRequests_itInjectsTrace() throws {
        // Given
        var request: URLRequest = .mockWith(url: "https://test.com")
        let writer = HTTPHeadersWriter(sampler: .mockKeepAll())
        handler.firstPartyHosts = .init(["test.com": [.datadog]])

        // When
        writer.write(traceID: .mock(1), spanID: .mock(2))
        request.allHTTPHeaderFields = writer.traceHeaderFields

        let task: URLSessionTask = .mockWith(request: request, response: .mockAny())
        let feature = try XCTUnwrap(core.get(feature: NetworkInstrumentationFeature.self))
        feature.intercept(task: task, additionalFirstPartyHosts: nil)
        feature.flush()

        // Then
        let interception = handler.interceptions.first?.value
        XCTAssertEqual(interception?.trace?.traceID, .mock(1))
        XCTAssertEqual(interception?.trace?.spanID, .mock(2))
    }

    func testGivenOpenTelemetry_b3single_whenInterceptingRequests_itInjectsTrace() throws {
        // Given
        var request: URLRequest = .mockWith(url: "https://test.com")
        let writer = OTelHTTPHeadersWriter(sampler: .mockKeepAll(), injectEncoding: .single)
        handler.firstPartyHosts = .init(["test.com": [.b3]])

        // When
        writer.write(traceID: .mock(1), spanID: .mock(2), parentSpanID: .mock(3))
        request.allHTTPHeaderFields = writer.traceHeaderFields

        let task: URLSessionTask = .mockWith(request: request, response: .mockAny())
        let feature = try XCTUnwrap(core.get(feature: NetworkInstrumentationFeature.self))
        feature.intercept(task: task, additionalFirstPartyHosts: nil)
        feature.flush()

        // Then
        let interception = handler.interceptions.first?.value
        XCTAssertEqual(interception?.trace?.traceID, .mock(1))
        XCTAssertEqual(interception?.trace?.spanID, .mock(2))
        XCTAssertEqual(interception?.trace?.parentSpanID, .mock(3))
    }

    func testGivenOpenTelemetry_b3multi_whenInterceptingRequests_itInjectsTrace() throws {
        // Given
        var request: URLRequest = .mockWith(url: "https://test.com")
        let writer = OTelHTTPHeadersWriter(sampler: .mockKeepAll(), injectEncoding: .multiple)
        handler.firstPartyHosts = .init(["test.com": [.b3multi]])

        // When
        writer.write(traceID: .mock(1), spanID: .mock(2), parentSpanID: .mock(3))
        request.allHTTPHeaderFields = writer.traceHeaderFields

        let task: URLSessionTask = .mockWith(request: request, response: .mockAny())
        let feature = try XCTUnwrap(core.get(feature: NetworkInstrumentationFeature.self))
        feature.intercept(task: task, additionalFirstPartyHosts: nil)
        feature.flush()

        // Then
        let interception = handler.interceptions.first?.value
        XCTAssertEqual(interception?.trace?.traceID, .mock(1))
        XCTAssertEqual(interception?.trace?.spanID, .mock(2))
        XCTAssertEqual(interception?.trace?.parentSpanID, .mock(3))
    }

    func testGivenW3C_whenInterceptingRequests_itInjectsTrace() throws {
        // Given
        var request: URLRequest = .mockWith(url: "https://test.com")
        let writer = W3CHTTPHeadersWriter(sampler: .mockKeepAll())
        handler.firstPartyHosts = .init(["test.com": [.tracecontext]])

        // When
        writer.write(traceID: .mock(1), spanID: .mock(2))
        request.allHTTPHeaderFields = writer.traceHeaderFields

        let task: URLSessionTask = .mockWith(request: request, response: .mockAny())
        let feature = try XCTUnwrap(core.get(feature: NetworkInstrumentationFeature.self))
        feature.intercept(task: task, additionalFirstPartyHosts: nil)
        feature.flush()

        // Then
        let interception = handler.interceptions.first?.value
        XCTAssertEqual(interception?.trace?.traceID, .mock(1))
        XCTAssertEqual(interception?.trace?.spanID, .mock(2))
    }

    // MARK: - First Party Hosts

//    func testGivenHandler_whenInterceptingRequests_itDetectFirstPartyHost() throws {
//        let notifyInterceptionStart = expectation(description: "Notify interception did start")
//        let server = ServerMock(delivery: .success(response: .mockResponseWith(statusCode: 200), data: .mock(ofSize: 10)))
//
//        // Given
//        let delegate = DatadogURLSessionDelegate(
//            in: core,
//            additionalFirstPartyHostsWithHeaderTypes: ["test.com": [.datadog]]
//        )
//        let session = server.getInterceptedURLSession(delegate: delegate)
//        let request: URLRequest = .mockWith(url: "https://test.com")
//
//        handler.onInterceptionStart = {
//            // Then
//            XCTAssertTrue($0.isFirstPartyRequest)
//            notifyInterceptionStart.fulfill()
//        }
//
//        // When
//        session
//            .dataTask(with: request)
//            .resume()
//
//        // Then
//        waitForExpectations(timeout: 1, handler: nil)
//        _ = server.waitAndReturnRequests(count: 1)
//    }

//    func testGivenDelegateSubclass_whenInterceptingRequests_itDetectFirstPartyHost() throws {
//        let notifyInterceptionStart = expectation(description: "Notify interception did start")
//        handler.onInterceptionStart = { _ in notifyInterceptionStart.fulfill() }
//        let server = ServerMock(delivery: .success(response: .mockResponseWith(statusCode: 200), data: .mock(ofSize: 10)))
//
//        // Given
//        class SubclassDelegate: DatadogURLSessionDelegate {}
//
//        let delegate = SubclassDelegate(
//            in: core,
//            additionalFirstPartyHostsWithHeaderTypes: ["test.com": [.datadog]]
//        )
//        let session = server.getInterceptedURLSession(delegate: delegate)
//        let request: URLRequest = .mockWith(url: "https://test.com")
//
//        handler.onInterceptionStart = {
//            // Then
//            XCTAssertTrue($0.isFirstPartyRequest)
//            notifyInterceptionStart.fulfill()
//        }
//
//        // When
//        session
//            .dataTask(with: request)
//            .resume()
//
//        // Then
//        waitForExpectations(timeout: 1, handler: nil)
//        _ = server.waitAndReturnRequests(count: 1)
//    }

//    func testGivenCompositeDelegate_whenInterceptingRequests_itDetectFirstPartyHost() throws {
//        let notifyInterceptionStart = expectation(description: "Notify interception did start")
//        handler.onInterceptionStart = { _ in notifyInterceptionStart.fulfill() }
//        let server = ServerMock(delivery: .success(response: .mockResponseWith(statusCode: 200), data: .mock(ofSize: 10)))
//
//        // Given
//        class CompositeDelegate: NSObject, URLSessionDataDelegate, __URLSessionDelegateProviding {
//            let ddURLSessionDelegate: DatadogURLSessionDelegate
//
//            required init(in core: DatadogCoreProtocol) {
//                ddURLSessionDelegate = DatadogURLSessionDelegate(
//                    in: core,
//                    additionalFirstPartyHostsWithHeaderTypes: ["test.com": [.datadog]]
//                )
//
//                super.init()
//            }
//        }
//
//        let delegate = CompositeDelegate(in: core)
//        let session = server.getInterceptedURLSession(delegate: delegate)
//        let request: URLRequest = .mockWith(url: "https://test.com")
//
//        handler.onInterceptionStart = {
//            // Then
//            XCTAssertTrue($0.isFirstPartyRequest)
//            notifyInterceptionStart.fulfill()
//        }
//
//        // When
//        session
//            .dataTask(with: request)
//            .resume()
//
//        // Then
//        waitForExpectations(timeout: 0.5, handler: nil)
//        _ = server.waitAndReturnRequests(count: 1)
//    }

    // MARK: - Thread Safety

    func testRandomlyCallingDifferentAPIsConcurrentlyDoesNotCrash() throws {
        let feature = try XCTUnwrap(core.get(feature: NetworkInstrumentationFeature.self))

        let requests = [
            URLRequest(url: URL(string: "https://api.first-party.com/v1/endpoint")!),
            URLRequest(url: URL(string: "https://api.third-party.com/v1/endpoint")!),
            URLRequest(url: URL(string: "https://dd.internal.com/v1/endpoint")!)
        ]
        let tasks = (0..<10).map { _ in URLSessionTask.mockWith(request: .mockAny(), response: .mockAny()) }

        // swiftlint:disable opening_brace trailing_closure
        callConcurrently(
            closures: [
                { feature.handlers = [self.handler] },
                { _ = feature.intercept(request: requests.randomElement()!, additionalFirstPartyHosts: nil) },
                { feature.intercept(task: tasks.randomElement()!, additionalFirstPartyHosts: nil) },
                { feature.task(tasks.randomElement()!, didReceive: .mockRandom()) },
                { feature.task(tasks.randomElement()!, didFinishCollecting: .mockAny()) },
                { feature.task(tasks.randomElement()!, didCompleteWithError: nil) }
            ],
            iterations: 50
        )
        // swiftlint:enable opening_brace trailing_closure
    }
}
